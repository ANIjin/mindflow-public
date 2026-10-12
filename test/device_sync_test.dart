import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/scheduler/schedule.dart';
import 'package:mindflow/core/sync/vault_sync.dart';

void main() {
  test('same passphrase maps to the same vault id', () {
    final a = VaultSyncClient.vaultIdForPassphrase('my-secret');
    final b = VaultSyncClient.vaultIdForPassphrase('my-secret');
    final c = VaultSyncClient.vaultIdForPassphrase('other');
    expect(a, b);
    expect(a == c, isFalse);
  });

  test('vault snapshot round-trips personal nodes', () async {
    final dir = Directory.systemTemp.createTempSync('mf_sync');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final mem = await MemoryStore.open(dir.path);
    final schedule = await ScheduleStore.open(dir.path);
    await mem.saveNode(MindNode(id: 'p1', title: 'Notes', body: 'x'));
    final snap = await VaultSyncClient.exportSnapshot(
      store: mem,
      schedule: schedule,
    );
    expect(snap.nodes.single['title'], 'Notes');

    final otherDir = Directory.systemTemp.createTempSync('mf_sync_other');
    addTearDown(() {
      try {
        otherDir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final other = await MemoryStore.open(otherDir.path);
    final otherSchedule = await ScheduleStore.open(otherDir.path);
    final changed = await VaultSyncClient.importSnapshot(
      store: other,
      schedule: otherSchedule,
      snap: snap,
    );
    expect(changed, greaterThan(0));
    expect(other.nodes['p1']?.title, 'Notes');
  });
}
