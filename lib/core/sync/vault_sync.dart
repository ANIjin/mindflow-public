import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../memory/memory_store.dart';
import '../models/node.dart';
import '../models/view_def.dart';
import '../scheduler/schedule.dart';

/// Snapshot of the personal vault for laptop ↔ phone sync.
class VaultSnapshot {
  final int version;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> views;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> chat;
  final List<Map<String, dynamic>> schedule;
  final Map<String, dynamic>? links;

  VaultSnapshot({
    this.version = 1,
    required this.updatedAt,
    required this.nodes,
    required this.views,
    required this.settings,
    required this.chat,
    required this.schedule,
    this.links,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'updatedAt': updatedAt.toIso8601String(),
        'nodes': nodes,
        'views': views,
        'settings': settings,
        'chat': chat,
        'schedule': schedule,
        'links': links,
      };

  factory VaultSnapshot.fromJson(Map<String, dynamic> j) => VaultSnapshot(
        version: j['version'] as int? ?? 1,
        updatedAt:
            DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
        nodes: _maps(j['nodes']),
        views: _maps(j['views']),
        settings: Map<String, dynamic>.from(j['settings'] as Map? ?? {}),
        chat: _maps(j['chat']),
        schedule: _maps(j['schedule']),
        links: j['links'] is Map
            ? Map<String, dynamic>.from(j['links'] as Map)
            : null,
      );

  static List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class SharePack {
  final String code;
  final String title;
  final List<Map<String, dynamic>> nodes;
  final DateTime createdAt;

  SharePack({
    required this.code,
    required this.title,
    required this.nodes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'nodes': nodes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SharePack.fromJson(Map<String, dynamic> j) => SharePack(
        code: j['code'] as String? ?? '',
        title: j['title'] as String? ?? 'Shared',
        nodes: VaultSnapshot._maps(j['nodes']),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Syncs one personal vault across devices using a shared passphrase.
///
/// Same sync URL + passphrase on laptop and phone → same vault.
/// No local user accounts.
class VaultSyncClient {
  static String normalizeSyncUrl(String raw) {
    var u = raw.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Stable id derived from the passphrase (never send the raw passphrase
  /// as a path segment; send as bearer secret).
  static String vaultIdForPassphrase(String passphrase) =>
      sha256.convert(utf8.encode('mindflow-vault::$passphrase')).toString();

  static Future<VaultSnapshot> exportSnapshot({
    required MemoryStore store,
    required ScheduleStore schedule,
  }) async {
    final chat = <Map<String, dynamic>>[];
    final chatFile = File(p.join(store.root, 'chat.jsonl'));
    if (chatFile.existsSync()) {
      for (final line in chatFile.readAsLinesSync()) {
        if (line.trim().isEmpty) continue;
        try {
          chat.add(Map<String, dynamic>.from(jsonDecode(line) as Map));
        } catch (_) {}
      }
    }
    Map<String, dynamic>? links;
    final linksFile = File(p.join(store.root, 'links.json'));
    if (linksFile.existsSync()) {
      try {
        links = Map<String, dynamic>.from(
            jsonDecode(linksFile.readAsStringSync()) as Map);
      } catch (_) {}
    }
    // Don't push local absolute memoryDir / secrets unnecessarily — keep AI
    // endpoint prefs so phone can reuse them if desired.
    return VaultSnapshot(
      updatedAt: DateTime.now(),
      nodes: store.nodes.values.map((n) => n.toJson()).toList(),
      views: store.views.values.map((v) => v.toJson()).toList(),
      settings: Map<String, dynamic>.from(store.settings)
        ..remove('memoryDir'),
      chat: chat,
      schedule: schedule.slots.map((s) => s.toJson()).toList(),
      links: links,
    );
  }

  static Future<int> importSnapshot({
    required MemoryStore store,
    required ScheduleStore schedule,
    required VaultSnapshot snap,
  }) async {
    var changed = 0;
    for (final raw in snap.nodes) {
      final incoming = MindNode.fromJson(raw);
      final existing = store.nodes[incoming.id];
      if (existing == null || incoming.updated.isAfter(existing.updated)) {
        await store.saveNode(incoming);
        changed++;
      }
    }
    for (final raw in snap.views) {
      final incoming = ViewDef.fromJson(raw);
      await store.saveView(incoming);
      changed++;
    }
    final merged = Map<String, dynamic>.from(snap.settings);
    // Keep this device's sync + path settings.
    for (final key in [
      'syncUrl',
      'syncPassphrase',
      'memoryDir',
    ]) {
      if (store.settings[key] != null) merged[key] = store.settings[key];
    }
    store.settings = merged;
    await store.saveSettings();

    schedule.slots
      ..clear()
      ..addAll(snap.schedule.map(ClassSlot.fromJson));
    await schedule.save();

    if (snap.chat.isNotEmpty) {
      final chatFile = File(p.join(store.root, 'chat.jsonl'));
      await chatFile.writeAsString(
          '${snap.chat.map(jsonEncode).join('\n')}\n');
    }
    return changed;
  }

  Map<String, String> _headers(String passphrase) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $passphrase',
        'X-Vault-Id': vaultIdForPassphrase(passphrase),
      };

  Future<void> pushVault({
    required String syncUrl,
    required String passphrase,
    required VaultSnapshot snapshot,
  }) async {
    final root = normalizeSyncUrl(syncUrl);
    if (root.isEmpty || passphrase.trim().isEmpty) {
      throw Exception('Set sync server URL and passphrase first');
    }
    final res = await http
        .put(Uri.parse('$root/v1/vault'),
            headers: _headers(passphrase.trim()),
            body: jsonEncode(snapshot.toJson()))
        .timeout(const Duration(seconds: 120));
    if (res.statusCode >= 300) {
      throw Exception('Sync push failed ${res.statusCode}: ${res.body}');
    }
  }

  Future<VaultSnapshot?> pullVault({
    required String syncUrl,
    required String passphrase,
  }) async {
    final root = normalizeSyncUrl(syncUrl);
    if (root.isEmpty || passphrase.trim().isEmpty) {
      throw Exception('Set sync server URL and passphrase first');
    }
    final res = await http
        .get(Uri.parse('$root/v1/vault'), headers: _headers(passphrase.trim()))
        .timeout(const Duration(seconds: 120));
    if (res.statusCode == 404) return null;
    if (res.statusCode >= 300) {
      throw Exception('Sync pull failed ${res.statusCode}: ${res.body}');
    }
    return VaultSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }

  Future<SharePack> createShare({
    required String syncUrl,
    required String passphrase,
    required String title,
    required List<MindNode> nodes,
  }) async {
    final root = normalizeSyncUrl(syncUrl);
    final res = await http
        .post(Uri.parse('$root/v1/shares'),
            headers: _headers(passphrase.trim()),
            body: jsonEncode({
              'title': title,
              'nodes': nodes.map((n) => n.toJson()).toList(),
            }))
        .timeout(const Duration(seconds: 60));
    if (res.statusCode >= 300) {
      throw Exception('Share failed ${res.statusCode}: ${res.body}');
    }
    return SharePack.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }

  Future<SharePack> redeemShare({
    required String syncUrl,
    required String passphrase,
    required String code,
  }) async {
    final root = normalizeSyncUrl(syncUrl);
    final res = await http.get(
      Uri.parse('$root/v1/shares/${Uri.encodeComponent(code.trim())}'),
      headers: _headers(passphrase.trim()),
    ).timeout(const Duration(seconds: 60));
    if (res.statusCode >= 300) {
      throw Exception('Redeem failed ${res.statusCode}: ${res.body}');
    }
    return SharePack.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map));
  }
}
