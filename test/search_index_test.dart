import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/models/node.dart';

void main() {
  test('query finds body text with block offset', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_search');
    final store = await MemoryStore.open(dir.path);
    final a = MindNode(
        id: 'a',
        title: 'Linear Algebra',
        body: '# Notes\n\nEigenvalues describe matrix transformations.');
    await store.saveNode(a);

    final hits = store.searchIndex.search('eigenvalues', store.nodes);
    expect(hits, isNotEmpty);
    expect(hits.first.nodeId, 'a');
    expect(hits.first.blockIndex, 1);
    expect(a.body.substring(hits.first.offset, hits.first.offset + 11).toLowerCase(),
        'eigenvalues');
    expect(hits.first.snippet.toLowerCase(), contains('eigenvalues'));

    dir.deleteSync(recursive: true);
  });

  test('deleted page removed from search results', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_search');
    final store = await MemoryStore.open(dir.path);
    await store.saveNode(MindNode(id: 'a', title: 'A', body: 'calculus limits'));
    await store.saveNode(MindNode(id: 'b', title: 'B', body: 'calculus series'));

    expect(store.searchIndex.search('calculus', store.nodes).length, 2);
    await store.deleteNode('a');
    final hits = store.searchIndex.search('calculus', store.nodes);
    expect(hits.length, 1);
    expect(hits.first.nodeId, 'b');

    dir.deleteSync(recursive: true);
  });

  test('search index persists across reopen', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_search');
    final store = await MemoryStore.open(dir.path);
    await store.saveNode(MindNode(id: 'a', title: 'A', body: 'thermodynamics'));
    expect(File('${dir.path}/search.json').existsSync(), isTrue);

    final reopened = await MemoryStore.open(dir.path);
    final hits = reopened.searchIndex.search('thermodynamics', reopened.nodes);
    expect(hits, isNotEmpty);
    expect(hits.first.nodeId, 'a');

    dir.deleteSync(recursive: true);
  });

  test('title, tags, and properties are indexed', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_search');
    final store = await MemoryStore.open(dir.path);
    await store.saveNode(MindNode(
        id: 'a',
        title: 'Organic Chemistry',
        body: 'plain text',
        tags: ['lab'],
        properties: {'professor': 'Dr Nguyen'}));

    expect(store.searchIndex.search('chemistry', store.nodes).first.nodeId, 'a');
    expect(store.searchIndex.search('lab', store.nodes).first.nodeId, 'a');
    expect(store.searchIndex.search('nguyen', store.nodes).first.nodeId, 'a');

    dir.deleteSync(recursive: true);
  });
}
