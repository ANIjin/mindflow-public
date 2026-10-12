import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/models/view_def.dart';
import 'package:mindflow/core/sync/memory_snapshot.dart';
import 'package:mindflow/core/sync/sync_models.dart';

void main() {
  test('memory snapshots have stable records and payloads', () async {
    final directory = await Directory.systemTemp.createTemp('mindflow_snapshot_');
    try {
      final store = await MemoryStore.open(directory.path);
      final node = MindNode(
        id: const Uuid().v4(),
        title: 'Page',
        body: '[[Other]]',
        updated: DateTime.utc(2026, 10, 7),
        links: const ['other'],
      );
      await store.saveNode(node);
      await store.saveView(ViewDef(id: 'view-1', name: 'Tasks'));

      final adapter = MemorySnapshotAdapter(store, deviceId: 'device-a');
      final first = adapter.snapshot();
      final second = adapter.snapshot();

      expect(first.records.map((record) => record.id).toList(),
          second.records.map((record) => record.id).toList());
      expect(adapter.encode(first), adapter.encode(second));
      expect(first.records.map((record) => record.kind),
          containsAll(<String>['node', 'link', 'database']));
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}