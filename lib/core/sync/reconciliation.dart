import 'sync_models.dart';

class SyncDelta {
  final List<SyncRecord> toSend;
  final List<SyncRecord> toApply;

  const SyncDelta({required this.toSend, required this.toApply});
}

class SyncReconciler {
  static SyncDelta diff(SyncManifest local, SyncManifest remote) {
    final localById = {for (final record in local.records) record.id: record};
    final remoteById = {for (final record in remote.records) record.id: record};
    final send = <SyncRecord>[];
    final apply = <SyncRecord>[];
    final ids = {...localById.keys, ...remoteById.keys}.toList()..sort();

    for (final id in ids) {
      final localRecord = localById[id];
      final remoteRecord = remoteById[id];
      if (localRecord == null) {
        apply.add(remoteRecord!);
      } else if (remoteRecord == null) {
        send.add(localRecord);
      } else {
        final comparison = compareRevisions(
            localRecord.revision, remoteRecord.revision);
        if (comparison < 0) {
          apply.add(remoteRecord);
        } else if (comparison > 0) {
          send.add(localRecord);
        }
      }
    }
    return SyncDelta(toSend: send, toApply: apply);
  }

  static int compareRevisions(SyncRevision a, SyncRevision b) {
    final counter = a.counter.compareTo(b.counter);
    if (counter != 0) return counter;
    final changedAt = a.changedAt.compareTo(b.changedAt);
    if (changedAt != 0) return changedAt;
    return a.deviceId.compareTo(b.deviceId);
  }
}