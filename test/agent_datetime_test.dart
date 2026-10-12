import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/ai/agent.dart';

void main() {
  test('system prompt includes authoritative local date and weekday', () {
    final at = DateTime(2026, 10, 9, 14, 30, 0); // Friday
    final prompt = buildSystemPrompt(at);
    expect(prompt, contains('Current local datetime:'));
    expect(prompt, contains('2026-10-09'));
    expect(prompt, contains('Friday'));
    expect(prompt, contains("Today's calendar date is 2026-10-09"));
    expect(prompt, contains('Do not guess the date'));
  });

  test('system prompt refreshes for a different day', () {
    final a = buildSystemPrompt(DateTime(2026, 1, 1, 9));
    final b = buildSystemPrompt(DateTime(2026, 12, 31, 23, 59));
    expect(a, contains('2026-01-01'));
    expect(a, contains('Thursday'));
    expect(b, contains('2026-12-31'));
    expect(b, contains('Thursday'));
    expect(a == b, isFalse);
  });
}
