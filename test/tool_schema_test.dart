import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/ai/tools.dart';

void main() {
  test('new vault tools are registered with schemas', () {
    final names = toolSchemas
        .map((e) => e['function']['name'] as String)
        .toSet();
    for (final n in [
      'create_page',
      'update_page_body',
      'append_block',
      'link_pages',
      'search',
      'create_database_view',
      'add_review_card',
      'grade_card',
      'plan_exams',
    ]) {
      expect(names, contains(n));
    }
  });
}
