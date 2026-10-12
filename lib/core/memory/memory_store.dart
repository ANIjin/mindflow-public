import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/links.dart';
import '../models/node.dart';
import '../models/view_def.dart';
import 'link_index.dart';
import 'search_index.dart';
import 'vault_mirror.dart';

class MemoryStore {
  final String root;
  final nodes = <String, MindNode>{};
  final views = <String, ViewDef>{};
  final linkIndex = LinkIndex();
  final searchIndex = SearchIndex();
  late final VaultMirror vault;
  Map<String, dynamic> settings = {
    'uiVersion': 1,
    'baseUrl': 'http://127.0.0.1:8080/v1',
    'model': 'swift-1.5-iq2_xs',
    'apiKey': '',
    'userName': '',
    'memoryDir': '',
    'integrations': {
      'autoSyncMinutes': 15,
      'blackboard': {
        'enabled': false,
        'baseUrl': '',
        'clientId': '',
        'clientSecret': '',
        'username': '',
        'password': '',
      },
      'aktiv': {
        'enabled': false,
        'loginUrl': '',
        'userField': 'login',
        'passField': 'password',
        'username': '',
        'password': '',
        'scrapeUrl': '',
        'itemRegex': '',
      },
      'outlook': {
        'enabled': false,
        'clientId': '14d82eec-204b-4c2f-b7e8-296a70d99351',
        'fetchMail': true,
        'tokens': {},
      },
    },
  };

  MemoryStore(this.root) : vault = VaultMirror(root);

  String get _nodesDir => p.join(root, 'nodes');
  String get _viewsDir => p.join(root, 'views');
  String get _chatFile => p.join(root, 'chat.jsonl');
  String get _memoryFile => p.join(root, 'memory.md');
  String get _logFile => p.join(root, 'log.jsonl');
  String get _settingsFile => p.join(root, 'settings.json');
  String get _linksFile => p.join(root, 'links.json');
  String get _searchFile => p.join(root, 'search.json');

  static Future<MemoryStore> open(String root) async {
    final store = MemoryStore(root);
    Directory(p.join(root, 'nodes')).createSync(recursive: true);
    Directory(p.join(root, 'views')).createSync(recursive: true);
    final mf = File(_rootFile(root, 'memory.md'));
    if (!mf.existsSync()) {
      mf.writeAsStringSync('# MindFlow Memory\n\nLong-term memory maintained by the MindFlow agent.\n');
    }
    final lf = File(_rootFile(root, 'log.jsonl'));
    if (!lf.existsSync()) lf.writeAsStringSync('');
    final cf = File(_rootFile(root, 'chat.jsonl'));
    if (!cf.existsSync()) cf.writeAsStringSync('');
    final sf = File(_rootFile(root, 'settings.json'));
    if (sf.existsSync()) {
      try {
        store.settings.addAll(
            (jsonDecode(sf.readAsStringSync()) as Map).cast<String, dynamic>());
      } catch (_) {}
    }
    store._loadNodes();
    store._loadViews();
    await store._migrateV2();
    store.vault.scan();
    for (final n in store.nodes.values) {
      await store.vault.writeMirror(n);
    }
    store.linkIndex.rebuild(store.nodes.values);
    await File(_rootFile(root, 'links.json')).writeAsString(store.linkIndex.encode());
    final searchF = File(_rootFile(root, 'search.json'));
    if (searchF.existsSync()) {
      store.searchIndex.load(searchF.readAsStringSync());
    } else {
      for (final n in store.nodes.values) {
        store.searchIndex.indexNode(n);
      }
      await searchF.writeAsString(store.searchIndex.encode());
    }
    return store;
  }

  Future<void> _migrateV2() async {
    final raw = settings['uiVersion'];
    final ver = raw is int ? raw : int.tryParse('$raw') ?? 1;
    if (ver >= 2) return;
    final ts =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final bak = p.join(root, 'backup', 'v1-$ts');
    Directory(p.join(bak, 'nodes')).createSync(recursive: true);
    Directory(p.join(bak, 'views')).createSync(recursive: true);
    for (final d in ['nodes', 'views']) {
      final src = Directory(p.join(root, d));
      if (!src.existsSync()) continue;
      for (final f in src.listSync()) {
        if (f is File && f.path.endsWith('.json')) {
          File(p.join(bak, d, p.basename(f.path)))
              .writeAsStringSync(f.readAsStringSync());
        }
      }
    }
    for (final n in nodes.values) {
      File(p.join(_nodesDir, '${n.id}.json'))
          .writeAsStringSync(jsonEncode(n.toJson()));
    }
    const layoutMap = {
      'list': 'list',
      'kanban': 'board',
      'grid': 'gallery',
      'calendar': 'calendar',
      'focus': 'list',
      'timeline': 'list',
    };
    for (final v in views.values) {
      final old = v.layout;
      v.layout = layoutMap[old] ?? 'list';
      if (old == 'focus') v.limit = 1;
      if (old == 'timeline') {
        v.sort = 'due';
        v.ascending = true;
      }
      if (v.filters.isEmpty) {
        if (v.status != null) {
          v.filters.add({'field': 'status', 'op': 'eq', 'value': v.status});
        }
        if (v.dueWithinDays != null) {
          v.filters.add({
            'field': 'due_within_days',
            'op': 'within',
            'value': v.dueWithinDays
          });
        }
        for (final t in v.tags) {
          v.filters.add({'field': 'tags', 'op': 'contains', 'value': t});
        }
        if (v.types.isNotEmpty) {
          v.filters.add({'field': 'types', 'op': 'in', 'value': v.types});
        }
      }
      File(p.join(_viewsDir, '${v.id}.json'))
          .writeAsStringSync(jsonEncode(v.toJson()));
    }
    settings['uiVersion'] = 2;
    settings['memoryDir'] = root;
    File(_settingsFile).writeAsStringSync(jsonEncode(settings));
    File(_logFile).writeAsStringSync(
        '${jsonEncode({'ts': DateTime.now().toIso8601String(), 'event': 'migration_v2', 'ref': '', 'detail': 'uiVersion=2 backup=$bak'})}\n',
        mode: FileMode.append);
  }

  static String _rootFile(String root, String name) => p.join(root, name);

  void _loadNodes() {
    nodes.clear();
    final dir = Directory(_nodesDir);
    if (!dir.existsSync()) return;
    for (final f in dir.listSync()) {
      if (f is File && f.path.endsWith('.json')) {
        try {
          final n = MindNode.fromJson(
              (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>());
          nodes[n.id] = n;
        } catch (_) {}
      }
    }
  }

  void _loadViews() {
    views.clear();
    final dir = Directory(_viewsDir);
    if (!dir.existsSync()) return;
    for (final f in dir.listSync()) {
      if (f is File && f.path.endsWith('.json')) {
        try {
          final v = ViewDef.fromJson(
              (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>());
          views[v.id] = v;
        } catch (_) {}
      }
    }
  }

  Future<void> saveNode(MindNode n) async {
    n.updated = DateTime.now();
    nodes[n.id] = n;
    syncNodeLinksAndTags(n, linkIndex.titleIndex(nodes.values));
    linkIndex.rebuild(nodes.values);
    searchIndex.indexNode(n);
    await File(p.join(_nodesDir, '${n.id}.json'))
        .writeAsString(jsonEncode(n.toJson()));
    await vault.writeMirror(n);
    await File(_linksFile).writeAsString(linkIndex.encode());
    await File(_searchFile).writeAsString(searchIndex.encode());
    await appendLog('node_saved', n.id, n.title);
  }

  Future<void> deleteNode(String id) async {
    nodes.remove(id);
    linkIndex.rebuild(nodes.values);
    searchIndex.unindexNode(id);
    final f = File(p.join(_nodesDir, '$id.json'));
    if (f.existsSync()) f.deleteSync();
    await vault.removeMirror(id);
    await File(_linksFile).writeAsString(linkIndex.encode());
    await File(_searchFile).writeAsString(searchIndex.encode());
    await appendLog('node_deleted', id, '');
  }

  Future<void> renameNode(String id, String newTitle) async {
    final node = nodes[id];
    if (node == null) return;
    final oldTitle = node.title;
    node.title = newTitle;
    for (final n in nodes.values) {
      if (n.id == id) continue;
      final updated = replaceWikilinkTitle(n.body, oldTitle, newTitle);
      if (updated != n.body) {
        n.body = updated;
        await saveNode(n);
      }
    }
    await saveNode(node);
    await appendLog('node_renamed', id, '$oldTitle -> $newTitle');
  }

  Future<void> saveView(ViewDef v) async {
    views[v.id] = v;
    await File(p.join(_viewsDir, '${v.id}.json'))
        .writeAsString(jsonEncode(v.toJson()));
    await appendLog('view_saved', v.id, v.name);
  }

  Future<void> deleteView(String id) async {
    views.remove(id);
    final f = File(p.join(_viewsDir, '$id.json'));
    if (f.existsSync()) f.deleteSync();
    await appendLog('view_deleted', id, '');
  }

  Future<void> appendLog(String event, String ref, String detail) async {
    final line = jsonEncode({
      'ts': DateTime.now().toIso8601String(),
      'event': event,
      'ref': ref,
      'detail': detail,
    });
    await File(_logFile).writeAsString('$line\n', mode: FileMode.append);
  }

  Future<List<Map<String, dynamic>>> readLog(int n) async {
    final f = File(_logFile);
    if (!f.existsSync()) return [];
    final lines = f.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
    final take = lines.length > n ? lines.sublist(lines.length - n) : lines;
    return take.map((l) => (jsonDecode(l) as Map).cast<String, dynamic>()).toList();
  }

  Future<String> readMemory() async {
    final f = File(_memoryFile);
    return f.existsSync() ? f.readAsString() : '';
  }

  Future<void> appendMemory(String entry) async {
    final f = File(_memoryFile);
    final ts = DateTime.now().toIso8601String().substring(0, 10);
    await f.writeAsString('\n**$ts** $entry\n', mode: FileMode.append);
    await appendLog('memory_write', '', entry);
  }

  Future<void> appendChat(String role, String content,
      [List<String> activity = const []]) async {
    final line = jsonEncode({
      'role': role,
      'content': content,
      'ts': DateTime.now().toIso8601String(),
      'activity': activity,
    });
    await File(_chatFile).writeAsString('$line\n', mode: FileMode.append);
  }

  Future<List<Map<String, dynamic>>> loadChat() async {
    final f = File(_chatFile);
    if (!f.existsSync()) return [];
    return f.readAsLinesSync().where((l) => l.trim().isNotEmpty).map((l) {
      try {
        return (jsonDecode(l) as Map).cast<String, dynamic>();
      } catch (_) {
        return <String, dynamic>{};
      }
    }).toList();
  }

  Future<void> saveSettings() async {
    settings['memoryDir'] = root;
    await File(_settingsFile).writeAsString(jsonEncode(settings));
  }

  List<MindNode> get activeNodes =>
      nodes.values.where((n) => n.status == 'active').toList();
}
