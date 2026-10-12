import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'core/ai/agent.dart';
import 'core/ai/ai_client.dart';
import 'core/ai/tools.dart';
import 'core/integrations/blackboard.dart';
import 'core/integrations/connector.dart';
import 'core/integrations/phone.dart';
import 'core/memory/database_engine.dart';
import 'core/memory/knowledge_base.dart';
import 'core/memory/memory_store.dart';
import 'core/memory/study_tools.dart';
import 'core/models/node.dart';
import 'core/models/view_def.dart';
import 'core/scheduler/notifications.dart';
import 'core/scheduler/schedule.dart';
import 'core/sync/vault_sync.dart';

class AppState extends ChangeNotifier {
  late MemoryStore store;
  late final AiClient client;
  late Agent agent;
  late ToolExecutor exec;
  late IntegrationManager integrations;
  late ScheduleStore schedule;
  late String docsRoot;
  final vaultSync = VaultSyncClient();
  Timer? syncTimer;
  Timer? vaultSyncTimer;
  final List<ChatMsg> chat = [];
  bool busy = false;
  String? lastError;
  String? syncStatus;

  String get syncUrl => (store.settings['syncUrl'] as String?)?.trim() ?? '';
  String get syncPassphrase =>
      (store.settings['syncPassphrase'] as String?) ?? '';
  bool get syncConfigured =>
      syncUrl.isNotEmpty && syncPassphrase.trim().isNotEmpty;

  static Future<AppState> init() async {
    final prefs = await SharedPreferences.getInstance();
    String docs;
    try {
      docs = (await getApplicationDocumentsDirectory()).path;
    } catch (_) {
      final home = Platform.isWindows
          ? Platform.environment['USERPROFILE']
          : Platform.environment['HOME'];
      docs = home ?? Directory.systemTemp.path;
      if (Platform.isWindows && home != null) {
        docs = p.join(home, 'Documents');
      }
    }
    final dir = prefs.getString('memoryDir') ?? p.join(docs, 'MindFlow');
    final state = await openForTest(dir);
    state.docsRoot = docs;
    try {
      await NotificationService.init();
      PhoneNotifier.configure(state.store);
      await NotificationService.rescheduleAll(state.store.nodes.values);
    } catch (_) {
      // Notifications are optional on headless / limited desktops.
    }
    await state._seed();
    state._startAutoSync();
    state._startVaultSync();
    return state;
  }

  /// Lightweight bootstrap for widget tests (no notifications / autosync).
  static Future<AppState> openForTest(String dir) async {
    final state = AppState();
    state.docsRoot = Directory.systemTemp.path;
    state.store = await MemoryStore.open(dir);
    state.schedule = await ScheduleStore.open(dir);
    state.integrations = IntegrationManager(state.store);
    state.client = AiClient(
      baseUrl: state.store.settings['baseUrl'] as String,
      model: state.store.settings['model'] as String,
      apiKey: state.store.settings['apiKey'] as String,
    );
    state.exec = ToolExecutor(state.store, state.integrations, state.schedule);
    state.agent = Agent(state.client, state.exec);
    for (final m in await state.store.loadChat()) {
      state.chat.add(ChatMsg(
        m['role'] as String? ?? 'user',
        m['content'] as String? ?? '',
        DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
        (m['activity'] as List?)?.map((e) => e as String).toList(),
      ));
    }
    return state;
  }

  void _startAutoSync() {
    syncTimer?.cancel();
    final mins = integrations.autoSyncMinutes;
    syncTimer = Timer.periodic(Duration(minutes: mins), (_) async {
      final c = await integrations.sync();
      if (c > 0) notifyListeners();
    });
    unawaited(integrations.sync().then((_) => notifyListeners()));
  }

  Future<int> syncNow() async {
    final c = await integrations.sync();
    notifyListeners();
    return c;
  }

  Future<String> outlookSignIn() async {
    return integrations.outlookSignIn();
  }

  bool get blackboardSignedIn =>
      integrations.connectors.whereType<BlackboardConnector>().first.signedIn;

  Future<String> blackboardRequestCode() async {
    final bc = integrations.connectors.whereType<BlackboardConnector>().first;
    final code = await bc.requestAuthCode();
    notifyListeners();
    return code;
  }

  Future<bool> blackboardExchangeCode(String code) async {
    final bc = integrations.connectors.whereType<BlackboardConnector>().first;
    final ok = await bc.exchangeCode(code);
    if (ok) await integrations.sync();
    notifyListeners();
    return ok;
  }

  Future<void> addClass(ClassSlot s) async {
    await schedule.addSlot(s);
    final page = ensureClassPage(store.nodes.values, s);
    await store.saveNode(page);
    notifyListeners();
  }

  Future<void> removeClass(String id) async {
    await schedule.removeSlot(id);
    notifyListeners();
  }

  Future<MindNode> ensureClassPageForSlot(ClassSlot s) async {
    final page = ensureClassPage(store.nodes.values, s);
    await store.saveNode(page);
    notifyListeners();
    return page;
  }

  Future<void> linkNoteAssignment(String noteId, String assignmentId) async {
    final note = store.nodes[noteId];
    final assignment = store.nodes[assignmentId];
    if (note == null || assignment == null) return;
    linkNoteToAssignment(note, assignment);
    await store.saveNode(note);
    await store.saveNode(assignment);
    notifyListeners();
  }

  Future<int> importIcs(String text) async {
    final n = await schedule.importIcs(text);
    notifyListeners();
    return n;
  }

  Future<void> _seed() async {
    if (store.views.isEmpty) {
      const uuid = Uuid();
      final seeds = [
        ViewDef(id: uuid.v4(), name: 'Focus Today', layout: 'focus', status: 'active', dueWithinDays: 7, sort: 'priority', ascending: false, order: 0, pinned: true),
        ViewDef(id: uuid.v4(), name: 'Assignments', layout: 'list', types: ['assignment'], status: 'active', sort: 'due', order: 1),
        ViewDef(id: uuid.v4(), name: 'Obligations', layout: 'list', types: ['obligation'], status: 'active', sort: 'due', order: 2),
        ViewDef(id: uuid.v4(), name: 'Goals', layout: 'grid', types: ['goal'], status: 'active', order: 3),
        ViewDef(id: uuid.v4(), name: 'Everything', layout: 'kanban', groupBy: 'status', order: 4),
      ];
      for (final v in seeds) {
        await store.saveView(v);
      }
    }
    notifyListeners();
  }

  void notify() => notifyListeners();

  String get themeChoice => store.settings['theme'] as String? ?? 'dark';

  Future<void> setThemeChoice(String choice) async {
    store.settings['theme'] = choice;
    await store.saveSettings();
    notifyListeners();
  }

  List<MindNode> sortedNodes() {
    final list = store.nodes.values.toList();
    list.sort((a, b) => a.status == 'active' && b.status != 'active'
        ? -1
        : b.status == 'active' && a.status != 'active'
            ? 1
            : b.updated.compareTo(a.updated));
    return list;
  }

  List<MindNode> applyView(ViewDef v) {
    return queryDatabase(store.nodes.values, v).nodes;
  }

  Future<void> sendChat(String text) async {
    if (busy || text.trim().isEmpty) return;
    busy = true;
    lastError = null;
    chat.add(ChatMsg('user', text, DateTime.now()));
    notifyListeners();
    try {
      exec.activities.clear();
      final result = await agent.run(text, chat);
      chat.add(ChatMsg('assistant', result.reply, DateTime.now(), result.activities));
      await store.appendChat('user', text);
      await store.appendChat('assistant', result.reply, result.activities);
    } catch (e) {
      lastError = e.toString();
      chat.add(ChatMsg('assistant', 'Error: $e', DateTime.now()));
    }
    busy = false;
    notifyListeners();
  }

  Future<void> reorganize() async {
    await sendChat(
        'Reorganize my board: inspect all nodes, views, memory and recent log. '
        'Create/update/delete/reorder views so the board best reflects my current '
        'priorities (deadlines this week, blocked items, goals). Then summarize in 3 lines.');
  }

  Future<void> saveNode(MindNode n) async {
    n.source = 'user';
    await store.saveNode(n);
    await NotificationService.syncNode(n);
    notifyListeners();
  }

  Future<void> completeNode(String id) async {
    final n = store.nodes[id];
    if (n == null) return;
    n.status = 'done';
    await store.saveNode(n);
    await NotificationService.syncNode(n);
    notifyListeners();
  }

  Future<void> deleteNode(String id) async {
    await store.deleteNode(id);
    await NotificationService.syncNode(MindNode(id: id, status: 'dropped'));
    notifyListeners();
  }

  Future<void> saveSettings({
    required String baseUrl,
    required String model,
    required String apiKey,
    required String userName,
    required String memoryDir,
  }) async {
    final normalized = AiClient.normalizeBaseUrl(baseUrl);
    store.settings['baseUrl'] = normalized;
    store.settings['model'] = model;
    store.settings['apiKey'] = apiKey;
    store.settings['userName'] = userName;
    client.baseUrl = normalized;
    client.model = model;
    client.apiKey = apiKey;
    if (memoryDir.isNotEmpty && memoryDir != store.root) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('memoryDir', memoryDir);
      store = await MemoryStore.open(memoryDir);
      schedule = await ScheduleStore.open(memoryDir);
      integrations = IntegrationManager(store);
      exec = ToolExecutor(store, integrations, schedule);
      agent = Agent(client, exec);
      chat.clear();
      for (final m in await store.loadChat()) {
        chat.add(ChatMsg(
          m['role'] as String? ?? 'user',
          m['content'] as String? ?? '',
          DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
          (m['activity'] as List?)?.map((e) => e as String).toList(),
        ));
      }
      await NotificationService.rescheduleAll(store.nodes.values);
      await _seed();
      _startAutoSync();
    }
    PhoneNotifier.configure(store);
    await store.saveSettings();
    notifyListeners();
  }

  void _startVaultSync() {
    vaultSyncTimer?.cancel();
    if (!syncConfigured) return;
    vaultSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(syncVault(quiet: true));
    });
  }

  Future<void> saveDeviceSync({
    required String syncUrl,
    required String passphrase,
  }) async {
    store.settings['syncUrl'] = VaultSyncClient.normalizeSyncUrl(syncUrl);
    store.settings['syncPassphrase'] = passphrase;
    await store.saveSettings();
    _startVaultSync();
    syncStatus = passphrase.trim().isEmpty
        ? 'Sync disabled'
        : 'Ready — use the same passphrase on your other devices';
    notifyListeners();
  }

  Future<String> syncVault({bool quiet = false}) async {
    if (!syncConfigured) {
      throw Exception('Set sync server URL and passphrase in Settings first');
    }
    try {
      if (!quiet) {
        syncStatus = 'Pulling…';
        notifyListeners();
      }
      final remote = await vaultSync.pullVault(
        syncUrl: syncUrl,
        passphrase: syncPassphrase,
      );
      var changed = 0;
      if (remote != null) {
        changed = await VaultSyncClient.importSnapshot(
          store: store,
          schedule: schedule,
          snap: remote,
        );
        chat.clear();
        for (final m in await store.loadChat()) {
          chat.add(ChatMsg(
            m['role'] as String? ?? 'user',
            m['content'] as String? ?? '',
            DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
            (m['activity'] as List?)?.map((e) => e as String).toList(),
          ));
        }
      }
      if (!quiet) {
        syncStatus = 'Pushing…';
        notifyListeners();
      }
      final snap = await VaultSyncClient.exportSnapshot(
        store: store,
        schedule: schedule,
      );
      await vaultSync.pushVault(
        syncUrl: syncUrl,
        passphrase: syncPassphrase,
        snapshot: snap,
      );
      store.settings['lastVaultSyncAt'] = DateTime.now().toIso8601String();
      await store.saveSettings();
      syncStatus =
          'Synced ${store.settings['lastVaultSyncAt']} (merged $changed remote change(s))';
      notifyListeners();
      return syncStatus!;
    } catch (e) {
      syncStatus = 'Sync error: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<String> shareNodes(List<String> nodeIds, {String? title}) async {
    if (!syncConfigured) {
      throw Exception('Configure device sync before sharing');
    }
    final nodes = nodeIds
        .map((id) => store.nodes[id])
        .whereType<MindNode>()
        .toList();
    if (nodes.isEmpty) throw Exception('No pages selected to share');
    final pack = await vaultSync.createShare(
      syncUrl: syncUrl,
      passphrase: syncPassphrase,
      title: title ?? nodes.first.title,
      nodes: nodes,
    );
    return pack.code;
  }

  Future<int> redeemShareCode(String code) async {
    if (!syncConfigured) {
      throw Exception('Configure device sync before redeeming a share');
    }
    final pack = await vaultSync.redeemShare(
      syncUrl: syncUrl,
      passphrase: syncPassphrase,
      code: code,
    );
    var n = 0;
    for (final raw in pack.nodes) {
      final node = MindNode.fromJson(raw);
      node.id = const Uuid().v4();
      node.source = 'shared';
      if (!node.tags.contains('shared')) node.tags.add('shared');
      node.properties['shareCode'] = pack.code;
      node.spaceId = node.spaceId ?? 'Shared';
      await store.saveNode(node);
      n++;
    }
    notifyListeners();
    return n;
  }

  Future<String> testConnection() async {
    try {
      final reply = await client.chat(
        [
          {
            'role': 'user',
            'content': 'Reply with exactly the two letters OK and nothing else.'
          }
        ],
        maxTokens: 32,
        tools: const [], // force plain completion; local models often choke on tools
      );
      final text = (reply.content ?? '').trim();
      if (text.isEmpty) return '(empty reply — model loaded?)';
      return text;
    } catch (e) {
      return 'ERROR: $e';
    }
  }
}
