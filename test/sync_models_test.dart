import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/sync/sync_models.dart';

void main() {
  test('device identity round-trips through JSON', () {
    const identity = DeviceIdentity(
      id: 'device-a',
      name: 'Laptop',
      platform: SyncPlatform.windows,
      appVersion: '1.2.3',
    );

    final decoded = DeviceIdentity.decode(identity.encode());

    expect(decoded.id, identity.id);
    expect(decoded.name, identity.name);
    expect(decoded.platform, identity.platform);
    expect(decoded.appVersion, identity.appVersion);
  });

  test('pairing and manifest preserve nested records', () {
    final changedAt = DateTime.utc(2026, 10, 7, 12);
    final remote = const DeviceIdentity(
      id: 'phone-a',
      name: 'Phone',
      platform: SyncPlatform.ios,
    );
    final record = SyncRecord(
      id: 'node-a',
      kind: 'node',
      payload: const {'title': 'A', 'links': ['node-b']},
      revision: SyncRevision(
        deviceId: 'phone-a',
        counter: 4,
        changedAt: changedAt,
      ),
    );
    final manifest = SyncManifest(sessionId: 'session-a', records: [record]);
    final pairing = Pairing(
      id: 'pair-a',
      remote: remote,
      transport: SyncTransport.wifi,
      confirmation: '123456',
      createdAt: changedAt,
      cursor: 'cursor-a',
    );

    final decodedManifest = SyncManifest.fromJson(manifest.toJson());
    final decodedPairing = Pairing.fromJson(pairing.toJson());

    expect(decodedManifest.sessionId, 'session-a');
    expect(decodedManifest.records.single.payload, record.payload);
    expect(decodedManifest.records.single.revision.counter, 4);
    expect(decodedPairing.remote.platform, SyncPlatform.ios);
    expect(decodedPairing.transport, SyncTransport.wifi);
    expect(decodedPairing.cursor, 'cursor-a');
  });
}