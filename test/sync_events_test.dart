import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/sync/sync_events.dart';
import 'package:mindflow/core/sync/sync_models.dart';

void main() {
  test('event bus emits progress and one terminal completion', () async {
    final bus = SyncEventBus();
    final events = <SyncProgress>[];
    final subscription = bus.events.listen(events.add);

    bus.publish(const SyncProgress(phase: SyncPhase.discovering));
    bus.publish(const SyncProgress(phase: SyncPhase.transferring, total: 2));
    bus.complete(transferred: 2, conflicts: 1);
    bus.fail('late failure');
    await bus.dispose();
    await subscription.cancel();

    expect(events.map((event) => event.phase), [
      SyncPhase.discovering,
      SyncPhase.transferring,
      SyncPhase.completed,
    ]);
    expect(events.last.message, '1 conflict(s)');
  });

  test('event bus reports cancellation as terminal', () async {
    final bus = SyncEventBus();
    final phases = <SyncPhase>[];
    final subscription = bus.events.listen((event) => phases.add(event.phase));

    bus.cancel();
    bus.publish(const SyncProgress(phase: SyncPhase.failed));
    await bus.dispose();
    await subscription.cancel();

    expect(phases, [SyncPhase.cancelled]);
  });
}