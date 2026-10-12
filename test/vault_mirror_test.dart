import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/models/node.dart';

String mirrorBody(String raw) {
  final lines = raw.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return '';
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      return lines.sublist(i + 1).join('\n').trim();
    }
  }
  return '';
}

void main() {
  test('saved page produces vault mirror matching its body', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_vault');
    final store = await MemoryStore.open(dir.path);
    final n = MindNode(
        id: 'a',
        title: 'Linear Algebra',
        body: '# Notes\n\nEigenvalues describe matrix transformations.');
    await store.saveNode(n);

    final f = File('${dir.path}/vault/general/Linear Algebra.md');
    expect(f.existsSync(), isTrue);
    final raw = f.readAsStringSync();
    expect(raw.startsWith('---'), isTrue);
    expect(raw, contains('id: a'));
    expect(raw, contains('title: "Linear Algebra"'));
    expect(mirrorBody(raw), n.body);

    dir.deleteSync(recursive: true);
  });

  test('mirror updates on save and is removed on delete', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_vault');
    final store = await MemoryStore.open(dir.path);
    final n = MindNode(id: 'a', title: 'A', body: 'first');
    await store.saveNode(n);

    n.body = 'second';
    await store.saveNode(n);
    final raw = File('${dir.path}/vault/general/A.md').readAsStringSync();
    expect(mirrorBody(raw), 'second');

    await store.deleteNode('a');
    expect(File('${dir.path}/vault/general/A.md').existsSync(), isFalse);

    dir.deleteSync(recursive: true);
  });

  test('rename moves the mirror file', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_vault');
    final store = await MemoryStore.open(dir.path);
    await store.saveNode(MindNode(id: 'a', title: 'Old Name', body: 'body'));

    await store.renameNode('a', 'New Name');

    expect(File('${dir.path}/vault/general/Old Name.md').existsSync(), isFalse);
    final raw = File('${dir.path}/vault/general/New Name.md').readAsStringSync();
    expect(raw, contains('title: "New Name"'));
    expect(mirrorBody(raw), 'body');

    dir.deleteSync(recursive: true);
  });

  test('mirrors generated for existing nodes on open', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_vault');
    final store = await MemoryStore.open(dir.path);
    await store.saveNode(MindNode(id: 'a', title: 'A', body: 'hello'));
    Directory('${dir.path}/vault').deleteSync(recursive: true);

    await MemoryStore.open(dir.path);
    expect(File('${dir.path}/vault/general/A.md').existsSync(), isTrue);

    dir.deleteSync(recursive: true);
  });

  test('title collision gets unique mirror file', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_vault');
    final store = await MemoryStore.open(dir.path);
    await store.saveNode(MindNode(id: 'a', title: 'Notes', body: 'one'));
    await store.saveNode(MindNode(id: 'b', title: 'Notes', body: 'two'));

    expect(File('${dir.path}/vault/general/Notes.md').existsSync(), isTrue);
    final b = File('${dir.path}/vault/general/Notes-b.md');
    expect(b.existsSync(), isTrue);
    expect(mirrorBody(b.readAsStringSync()), 'two');

    dir.deleteSync(recursive: true);
  });

  test('space id becomes mirror subdirectory', () async {
    final dir = Directory.systemTemp.createTempSync('mindflow_vault');
    final store = await MemoryStore.open(dir.path);
    await store.saveNode(
        MindNode(id: 'a', title: 'A', body: 'x', spaceId: 'physics'));

    expect(File('${dir.path}/vault/physics/A.md').existsSync(), isTrue);

    dir.deleteSync(recursive: true);
  });
}
