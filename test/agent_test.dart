import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/ai/agent.dart';
import 'package:mindflow/core/ai/ai_client.dart';
import 'package:mindflow/core/ai/tools.dart';
import 'package:mindflow/core/memory/memory_store.dart';

void main() {
  test('agent creates node via strata', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_agent');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final store = await MemoryStore.open(dir.path);
    final client = AiClient(
        baseUrl: 'http://127.0.0.1:8080/v1', model: 'swift-1.5-iq2_xs');
    final exec = ToolExecutor(store);
    final agent = Agent(client, exec);
    final r = await agent.run(
        'I have a math assignment due 2026-10-05T17:00:00. Create it with a '
        'reminder the day before.',
        []);
    // ignore: avoid_print
    print('REPLY: ${r.reply}');
    // ignore: avoid_print
    print('ACTIVITIES: ${r.activities}');
    // ignore: avoid_print
    print('NODES: ${store.nodes.values.map((n) => n.toSummary()).join('\n')}');
    expect(store.nodes.length, greaterThan(0));
    expect(store.nodes.values.any((n) => n.reminders.isNotEmpty), true);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
