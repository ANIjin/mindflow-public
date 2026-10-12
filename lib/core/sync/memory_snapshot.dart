import 'dart:convert';

import '../memory/memory_store.dart';
import 'sync_models.dart';

class MemorySnapshotAdapter {
  final MemoryStore store;
  final String deviceId;

  const MemorySnapshotAdapter(this.store, {required this.deviceId});

  SyncManifest snapshot({String sessionId = 'snapshot'}) {
    final records = <SyncRecord>[];
    final nodes = store.nodes.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final node in nodes) {
      records.add(SyncRecord(
        id: node.id,
        kind: 'node',
        payload: _stableMap(node.toJson()),
        revision: SyncRevision(
          deviceId: deviceId,
          counter: node.updated.microsecondsSinceEpoch,
          changedAt: node.updated.toUtc(),
        ),
      ));
      records.add(SyncRecord(
        id: 'links:${node.id}',
        kind: 'link',
        payload: {
          'source': node.id,
          'targets': List<String>.from(node.links)..sort(),
        },
        revision: SyncRevision(
          deviceId: deviceId,
          counter: node.updated.microsecondsSinceEpoch,
          changedAt: node.updated.toUtc(),
        ),
      ));
    }
    final views = store.views.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final view in views) {
      records.add(SyncRecord(
        id: view.id,
        kind: 'database',
        payload: _stableMap(view.toJson()),
        revision: SyncRevision(
          deviceId: deviceId,
          counter: view.order,
          changedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
      ));
    }
    return SyncManifest(sessionId: sessionId, records: records);
  }

  Map<String, dynamic> _stableMap(Map<String, dynamic> value) {
    final keys = value.keys.toList()..sort();
    return {
      for (final key in keys) key: _stableValue(value[key]),
    };
  }

  dynamic _stableValue(dynamic value) {
    if (value is Map) {
      return _stableMap(value.cast<String, dynamic>());
    }
    if (value is List) {
      return value.map(_stableValue).toList();
    }
    return value;
  }

  String encode(SyncManifest manifest) => jsonEncode(manifest.toJson());
}