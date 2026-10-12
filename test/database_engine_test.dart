import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/database_engine.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/models/view_def.dart';

void main() {
  final nodes = [
    MindNode(id: '1', title: 'A', type: 'assignment', status: 'active', priority: 2,
        due: DateTime(2026, 10, 1), tags: ['math']),
    MindNode(id: '2', title: 'B', type: 'assignment', status: 'done', priority: 1,
        due: DateTime(2026, 10, 10), tags: ['math']),
    MindNode(id: '3', title: 'C', type: 'goal', status: 'active', priority: 3,
        due: DateTime(2026, 9, 1), tags: ['life']),
  ];

  test('ViewDef columns and filters round-trip via JSON', () {
    final v = ViewDef(
      id: 'v',
      name: 'Deadlines',
      layout: 'table',
      columns: ['title', 'due'],
      filters: [
        {'field': 'type', 'op': 'eq', 'value': 'assignment'},
        {'field': 'status', 'op': 'eq', 'value': 'active'},
      ],
    );
    final back = ViewDef.fromJson(v.toJson());
    expect(back.columns, ['title', 'due']);
    expect(back.filters.length, 2);
    expect(back.filters.first['field'], 'type');
  });

  test('engine AND filters, sorts, groups, and counts', () {
    final view = ViewDef(
      id: 'v',
      layout: 'board',
      filters: [
        {'field': 'type', 'op': 'eq', 'value': 'assignment'},
      ],
      sort: 'priority',
      ascending: true,
      groupBy: 'status',
    );
    final result = queryDatabase(nodes, view);
    expect(result.count, 2);
    expect(result.nodes.map((n) => n.id).toList(), ['2', '1']);
    expect(result.groups.keys, containsAll(['active', 'done']));
  });

  test('visibleColumns hides unselected fields', () {
    final view = ViewDef(id: 'v', columns: ['title', 'due']);
    expect(visibleColumns(view), ['title', 'due']);
    expect(visibleColumns(view), isNot(contains('priority')));
  });
}
