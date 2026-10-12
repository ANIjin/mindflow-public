import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/models/view_def.dart';

void main() {
  test('MindNode round-trips all fields including new v2 fields', () {
    final n = MindNode(
      id: 'n1',
      type: 'note',
      title: 'Round trip',
      body: '# Heading\n\n- [x] done\n',
      due: DateTime.parse('2026-10-05T17:00:00.000'),
      reminders: [DateTime.parse('2026-10-04T09:00:00.000')],
      priority: 3,
      status: 'blocked',
      tags: ['a', 'b'],
      links: ['n2'],
      meta: {'k': 1},
      style: {'color': 'red'},
      created: DateTime.parse('2026-09-01T08:00:00.000'),
      updated: DateTime.parse('2026-09-02T08:00:00.000'),
      source: 'agent',
      parentId: 'p1',
      spaceId: 's1',
      properties: {'difficulty': 'hard', 'effort': 4},
      icon: 'book',
      cover: 'cover.png',
      review: ReviewState(
        due: DateTime.parse('2026-10-10T08:00:00.000'),
        interval: 4.0,
        ease: 2.2,
        reps: 3,
        lapses: 1,
      ),
    );
    final j = jsonDecode(jsonEncode(n.toJson())) as Map;
    final r = MindNode.fromJson(j.cast<String, dynamic>());
    expect(r.id, 'n1');
    expect(r.type, 'note');
    expect(r.title, 'Round trip');
    expect(r.body, '# Heading\n\n- [x] done\n');
    expect(r.due, DateTime.parse('2026-10-05T17:00:00.000'));
    expect(r.reminders.length, 1);
    expect(r.priority, 3);
    expect(r.status, 'blocked');
    expect(r.tags, ['a', 'b']);
    expect(r.links, ['n2']);
    expect(r.meta['k'], 1);
    expect(r.style['color'], 'red');
    expect(r.source, 'agent');
    expect(r.parentId, 'p1');
    expect(r.spaceId, 's1');
    expect(r.properties['difficulty'], 'hard');
    expect(r.properties['effort'], 4);
    expect(r.icon, 'book');
    expect(r.cover, 'cover.png');
    expect(r.review!.due, DateTime.parse('2026-10-10T08:00:00.000'));
    expect(r.review!.interval, 4.0);
    expect(r.review!.ease, 2.2);
    expect(r.review!.reps, 3);
    expect(r.review!.lapses, 1);
  });

  test('MindNode defaults for missing v2 fields', () {
    final j = (jsonDecode(jsonEncode({
      'id': 'n2',
    })) as Map).cast<String, dynamic>();
    final r = MindNode.fromJson(j);
    expect(r.parentId, isNull);
    expect(r.spaceId, isNull);
    expect(r.properties, isEmpty);
    expect(r.icon, isNull);
    expect(r.cover, isNull);
    expect(r.review, isNull);
  });

  test('ViewDef round-trips columns, filters, and limit', () {
    final v = ViewDef(
      id: 'v1',
      name: 'Board',
      layout: 'board',
      types: ['task'],
      tags: ['x'],
      status: 'active',
      dueWithinDays: 7,
      sort: 'priority',
      ascending: false,
      groupBy: 'status',
      order: 2,
      pinned: true,
      style: {'density': 'compact'},
      columns: ['title', 'status', 'due'],
      filters: [
        {'field': 'status', 'op': 'eq', 'value': 'active'},
        {'field': 'tags', 'op': 'contains', 'value': 'x'},
      ],
      limit: 20,
    );
    final j = (jsonDecode(jsonEncode(v.toJson())) as Map)
        .cast<String, dynamic>();
    final r = ViewDef.fromJson(j);
    expect(r.layout, 'board');
    expect(r.columns, ['title', 'status', 'due']);
    expect(r.filters.length, 2);
    expect(r.filters[0]['field'], 'status');
    expect(r.filters[1]['value'], 'x');
    expect(r.limit, 20);
    expect(r.pinned, isTrue);
    expect(r.ascending, isFalse);
    expect(r.dueWithinDays, 7);
  });

  test('ViewDef defaults for missing v2 fields', () {
    final j = (jsonDecode(jsonEncode({
      'id': 'v2',
    })) as Map).cast<String, dynamic>();
    final r = ViewDef.fromJson(j);
    expect(r.columns, isEmpty);
    expect(r.filters, isEmpty);
    expect(r.limit, isNull);
  });
}
