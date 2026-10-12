import 'dart:async';

import 'sync_models.dart';

enum SyncOutcome { success, failed, cancelled }

class SyncResult {
  final SyncOutcome outcome;
  final int transferred;
  final int conflicts;
  final String? message;

  const SyncResult({
    required this.outcome,
    this.transferred = 0,
    this.conflicts = 0,
    this.message,
  });
}

class SyncEventBus {
  final StreamController<SyncProgress> _controller =
      StreamController<SyncProgress>.broadcast();
  bool _terminal = false;

  Stream<SyncProgress> get events => _controller.stream;

  void publish(SyncProgress progress) {
    if (_terminal || _controller.isClosed) return;
    if (progress.phase == SyncPhase.completed ||
        progress.phase == SyncPhase.failed ||
        progress.phase == SyncPhase.cancelled) {
      _terminal = true;
    }
    _controller.add(progress);
  }

  void complete({int transferred = 0, int conflicts = 0}) => publish(
        SyncProgress(
          phase: SyncPhase.completed,
          completed: transferred,
          total: transferred,
          message: conflicts == 0 ? null : '$conflicts conflict(s)',
        ),
      );

  void fail(String message) =>
      publish(SyncProgress(phase: SyncPhase.failed, message: message));

  void cancel() => publish(const SyncProgress(phase: SyncPhase.cancelled));

  Future<void> dispose() => _controller.close();
}