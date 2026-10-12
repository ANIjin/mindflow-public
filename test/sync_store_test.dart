import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/sync/sync_models.dart';
import 'package:mindflow/core/sync/sync_store.dart';

void main() {
  test('sync metadata persists independently from memory settings', () async {
    final directory = await Directory.systemTemp.createTemp('mindflow_sync_');
    try {
      final memory = await MemoryStore.open(directory.path);
      final integrations = (memory.settings['integrations'] as Map)
          .cast<String, dynamic>();
      integrations['autoSyncMinutes'] = 27;
      await memory.saveSettings();

      final sync = await SyncStore.open(
        root: directory.path,
        deviceName: 'Laptop',
      );
      final pairing = Pairing(
        id: 'pair-1',
        remote: const DeviceIdentity(
          id: 'phone-1',
          name: 'Phone',
          platform: SyncPlatform.ios,
        ),
        transport: SyncTransport.wifi,
        confirmation: '123456',
        createdAt: DateTime.utc(2026, 10, 7),
      );
      await sync.savePairing(pairing);
      await sync.recordSync('pair-1', cursor: 'cursor-1');

      final reopened = await SyncStore.open(root: directory.path);
      expect(reopened.localDevice.id, sync.localDevice.id);
      expect(reopened.pairings['pair-1']!.cursor, 'cursor-1');
      expect(reopened.pairings['pair-1']!.lastSyncAt, isNotNull);

      final reopenedMemory = await MemoryStore.open(directory.path);
      expect(
          (reopenedMemory.settings['integrations'] as Map)['autoSyncMinutes'],
          27);
      expect(File('${directory.path}/settings.json').existsSync(), isTrue);

      await reopened.removePairing('pair-1');
      expect((await SyncStore.open(root: directory.path)).pairings, isEmpty);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}