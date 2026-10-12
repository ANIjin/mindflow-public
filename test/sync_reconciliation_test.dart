import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/sync/reconciliation.dart';
import 'package:mindflow/core/sync/sync_models.dart';

SyncRecord record(String id, String device, int counter) => SyncRecord(
      id: id,
      kind: 'node',
      payload: {'id': id, 'counter': counter},
      revision: SyncRevision(
        deviceId: device,
        counter: counter,
        changedAt: DateTime.utc(2026, 10, 7),
      ),
    );

void main() {
  test('diff selects new and newer records in both directions', () {
    final local = SyncManifest(sessionId: 'local', records: [
      record('shared', 'laptop', 2),
      record('local-only', 'laptop', 1),
    ]);
    final remote = SyncManifest(sessionId: 'remote', records: [
      record('shared', 'phone', 1),
      record('remote-only', 'phone', 1),
    ]);

    final delta = SyncReconciler.diff(local, remote);

    expect(delta.toSend.map((item) => item.id), ['local-only', 'shared']);
    expect(delta.toApply.map((item) => item.id), ['remote-only']);
  });

  test('equal manifests produce no duplicate work', () {
    final manifest = SyncManifest(sessionId: 'same', records: [
      record('node-1', 'laptop', 1),
      record('node-2', 'laptop', 2),
    ]);

    final delta = SyncReconciler.diff(manifest, manifest);

    expect(delta.toSend, isEmpty);
    expect(delta.toApply, isEmpty);
  });
}