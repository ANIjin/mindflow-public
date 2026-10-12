import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/sync/conflict_resolver.dart';
import 'package:mindflow/core/sync/sync_models.dart';
import 'package:mindflow/core/sync/sync_store.dart';

SyncRecord changed(String device, int counter, String body) => SyncRecord(
      id: 'page-1',
      kind: 'node',
      payload: {'body': body},
      revision: SyncRevision(
        deviceId: device,
        counter: counter,
        changedAt: DateTime.utc(2026, 10, 7),
      ),
    );

void main() {
  test('conflicts choose the same winner and preserve the variant', () async {
    final local = changed('laptop', 4, 'laptop edit');
    final remote = changed('phone', 4, 'phone edit');
    const resolver = SyncConflictResolver();
    final first = resolver.resolve(local, remote);
    final second = resolver.resolve(remote, local);

    expect(first.winner.payload, second.winner.payload);
    expect(first.variant.payload, second.variant.payload);

    final directory = await Directory.systemTemp.createTemp('mindflow_conflict_');
    try {
      final store = await SyncStore.open(root: directory.path);
      await store.saveConflict(first);
      final reopened = await SyncStore.open(root: directory.path);
      expect(reopened.conflicts[first.id]!.variant.payload,
          first.variant.payload);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}