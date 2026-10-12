import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/memory_store.dart';

void main() {
  const legacyNode = {
    'id': 'n1',
    'type': 'task',
    'title': 'Legacy task',
    'body': 'plain text body',
    'due': '2026-10-05T17:00:00.000',
    'reminders': ['2026-10-04T09:00:00.000'],
    'priority': 2,
    'status': 'active',
    'tags': ['school'],
    'links': [],
    'meta': {},
    'style': {},
    'created': '2026-09-01T08:00:00.000',
    'updated': '2026-09-02T08:00:00.000',
    'source': 'user',
  };

  const legacyView = {
    'id': 'v1',
    'name': 'Everything',
    'layout': 'kanban',
    'types': [],
    'tags': [],
    'status': 'active',
    'due_within_days': null,
    'sort': 'due',
    'ascending': true,
    'group_by': 'status',
    'order': 4,
    'pinned': false,
    'style': {},
  };

  const legacySettings = {
    'baseUrl': 'http://custom:9/v1',
    'model': 'custom-model',
    'apiKey': 'k',
    'userName': 'Demo',
    'memoryDir': '',
  };

  String seedStore(Directory dir) {
    Directory('${dir.path}/nodes').createSync(recursive: true);
    Directory('${dir.path}/views').createSync(recursive: true);
    File('${dir.path}/nodes/n1.json')
        .writeAsStringSync(jsonEncode(legacyNode));
    File('${dir.path}/views/v1.json')
        .writeAsStringSync(jsonEncode(legacyView));
    File('${dir.path}/settings.json')
        .writeAsStringSync(jsonEncode(legacySettings));
    File('${dir.path}/chat.jsonl').writeAsStringSync(
        '${jsonEncode({'role': 'user', 'content': 'hi', 'ts': '2026-09-03T10:00:00.000', 'activity': []})}\n');
    return dir.path;
  }

  test('pre-change store opens with everything intact and a backup exists',
      () async {
    final dir = Directory.systemTemp.createTempSync('mf_mig');
    seedStore(dir);
    final store = await MemoryStore.open(dir.path);

    expect(store.nodes['n1']!.title, 'Legacy task');
    expect(store.nodes['n1']!.body, 'plain text body');
    expect(store.nodes['n1']!.due, DateTime.parse('2026-10-05T17:00:00.000'));
    expect(store.nodes['n1']!.reminders.length, 1);
    expect(store.nodes['n1']!.properties, isEmpty);
    expect(store.nodes['n1']!.review, isNull);
    expect(store.nodes['n1']!.parentId, isNull);

    expect(store.views['v1']!.layout, 'board');
    expect(store.views['v1']!.filters, contains(equals(<String, dynamic>{
          'field': 'status',
          'op': 'eq',
          'value': 'active'
        })));

    expect(store.settings['baseUrl'], 'http://custom:9/v1');
    expect(store.settings['model'], 'custom-model');
    expect(store.settings['userName'], 'Demo');
    expect(store.settings['uiVersion'], 2);

    final chat = await store.loadChat();
    expect(chat.length, 1);
    expect(chat[0]['content'], 'hi');

    final backups = Directory('${dir.path}/backup').listSync();
    expect(backups.length, 1);
    final bak = backups[0] as Directory;
    final bakNode = File('${bak.path}/nodes/n1.json').readAsStringSync();
    expect(jsonDecode(bakNode)['title'], 'Legacy task');
    expect(jsonDecode(bakNode).containsKey('properties'), isFalse);
    final bakView = File('${bak.path}/views/v1.json').readAsStringSync();
    expect(jsonDecode(bakView)['layout'], 'kanban');

    final store2 = await MemoryStore.open(dir.path);
    expect(store2.settings['uiVersion'], 2);
    expect(store2.nodes['n1']!.title, 'Legacy task');
    expect(store2.views['v1']!.layout, 'board');
    expect(Directory('${dir.path}/backup').listSync().length, 1);

    dir.deleteSync(recursive: true);
  });
}