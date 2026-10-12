import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'reconciliation.dart';
import 'sync_models.dart';

class SyncConflictResolver {
  const SyncConflictResolver();

  ConflictRecord resolve(SyncRecord local, SyncRecord remote) {
    final localJson = jsonEncode(local.toJson());
    final remoteJson = jsonEncode(remote.toJson());
    final localWins = SyncReconciler.compareRevisions(
          local.revision, remote.revision,
        ) >=
        0;
    final winner = localWins ? local : remote;
    final variant = localWins ? remote : local;
    return ConflictRecord(
      id: const Uuid().v5(Uuid.NAMESPACE_URL, '$localJson|$remoteJson'),
      recordId: local.id,
      winner: winner,
      variant: variant,
      createdAt: DateTime.now().toUtc(),
    );
  }
}