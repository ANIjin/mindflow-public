import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/models/node.dart';

void main() {
  test('save updates persisted link index', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_link_index');
    final store = await MemoryStore.open(dir.path);
    final a = MindNode(id: 'a', title: 'A', body: '[[B]]');
    final b = MindNode(id: 'b', title: 'B');
    await store.saveNode(b);
    await store.saveNode(a);

    expect(store.linkIndex.out['a'], contains('b'));
    expect(store.linkIndex.in_['b'], contains('a'));
    expect(File('${dir.path}/links.json').existsSync(), isTrue);

    dir.deleteSync(recursive: true);
  });

  test('rename updates inbound links and index', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_link_index');
    final store = await MemoryStore.open(dir.path);
    final a = MindNode(id: 'a', title: 'A', body: '[[B]]');
    final b = MindNode(id: 'b', title: 'B');
    await store.saveNode(b);
    await store.saveNode(a);

    await store.renameNode('b', 'B2');

    expect(a.body, contains('[[B2]]'));
    expect(store.linkIndex.in_['b'], contains('a'));
    expect(store.linkIndex.titleIndex(store.nodes.values)['b2'], 'b');

    dir.deleteSync(recursive: true);
  });

  test('delete removes entries from link index', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_link_index');
    final store = await MemoryStore.open(dir.path);
    final a = MindNode(id: 'a', title: 'A', body: '[[B]]');
    final b = MindNode(id: 'b', title: 'B');
    await store.saveNode(b);
    await store.saveNode(a);

    await store.deleteNode('b');

    expect(store.linkIndex.out['a'], isNot(contains('b')));
    expect(store.linkIndex.in_.containsKey('b'), isFalse);

    dir.deleteSync(recursive: true);
  });
}
