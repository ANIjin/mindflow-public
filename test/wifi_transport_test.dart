import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/sync/sync_models.dart';
import 'package:mindflow/core/sync/sync_protocol.dart';
import 'package:mindflow/core/sync/wifi_transport.dart';

void main() {
  test('two local WiFi peers discover and exchange a handshake', () async {
    final serverReady = Completer<WifiSyncSession>();
    final laptop = const DeviceIdentity(
      id: 'laptop',
      name: 'Laptop',
      platform: SyncPlatform.windows,
    );
    final desktop = const DeviceIdentity(
      id: 'desktop',
      name: 'Desktop',
      platform: SyncPlatform.windows,
    );
    final server = WifiTransportAdapter(desktop, onSession: (session) {
      if (!serverReady.isCompleted) serverReady.complete(session);
    });
    final client = WifiTransportAdapter(laptop);
    await server.start();
    await client.start();
    try {
      final peers = await client.discover(timeout: const Duration(milliseconds: 30));
      expect(peers.map((peer) => peer.id), contains('desktop'));
      final clientSession = await client.connect(desktop);
      final serverSession = await serverReady.future;
      await clientSession.sendFrame(SyncHandshake.request(laptop));
      final remote = SyncHandshake.accept(await serverSession.receiveFrame());
      expect(remote.id, 'laptop');
      await clientSession.close();
      await serverSession.close();
    } finally {
      await client.stop();
      await server.stop();
    }
  });
}