import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/models/blocks.dart';

void main() {
  test('heading blocks with levels 1-3', () {
    final b = parseBlocks('# One\n\n## Two\n\n### Three');
    expect(b.length, 3);
    expect(b[0].type, BlockType.heading);
    expect(b[0].level, 1);
    expect(b[0].text, 'One');
    expect(b[1].level, 2);
    expect(b[2].level, 3);
    expect(b[0].toMarkdown(), '# One');
  });

  test('todo blocks checked and unchecked', () {
    final b = parseBlocks('- [ ] buy milk\n- [x] ship report');
    expect(b.length, 2);
    expect(b[0].type, BlockType.todo);
    expect(b[0].checked, isFalse);
    expect(b[0].text, 'buy milk');
    expect(b[1].checked, isTrue);
    expect(b[1].toMarkdown(), '- [x] ship report');
  });

  test('toggle block nests children', () {
    final b = parseBlocks('> [!toggle]\n> - a\n> - b');
    expect(b.length, 1);
    expect(b[0].type, BlockType.toggle);
    expect(b[0].children.length, 1);
    expect(b[0].children[0].type, BlockType.bulleted);
    expect(b[0].children[0].items, ['a', 'b']);
    expect(b[0].toMarkdown(), '> [!toggle]\n> - a\n> - b');
  });

  test('callout block keeps kind, title, and content', () {
    final b = parseBlocks('> [!warning] Deadline\n> submit by friday');
    expect(b.length, 1);
    expect(b[0].type, BlockType.callout);
    expect(b[0].kind, 'warning');
    expect(b[0].text, 'Deadline');
    expect(b[0].items, ['submit by friday']);
    expect(b[0].toMarkdown(), '> [!warning] Deadline\n> submit by friday');
  });

  test('code block keeps language and source', () {
    final b = parseBlocks('```dart\nvoid main() {}\n```');
    expect(b.length, 1);
    expect(b[0].type, BlockType.code);
    expect(b[0].lang, 'dart');
    expect(b[0].text, 'void main() {}');
    expect(b[0].toMarkdown(), '```dart\nvoid main() {}\n```');
  });

  test('quote block joins quoted lines', () {
    final b = parseBlocks('> line one\n> line two');
    expect(b.length, 1);
    expect(b[0].type, BlockType.quote);
    expect(b[0].text, 'line one\nline two');
    expect(b[0].toMarkdown(), '> line one\n> line two');
  });

  test('bulleted list groups consecutive items', () {
    final b = parseBlocks('- one\n- two\n- three');
    expect(b.length, 1);
    expect(b[0].type, BlockType.bulleted);
    expect(b[0].items, ['one', 'two', 'three']);
    expect(b[0].toMarkdown(), '- one\n- two\n- three');
  });

  test('numbered list groups consecutive items', () {
    final b = parseBlocks('1. first\n2. second');
    expect(b.length, 1);
    expect(b[0].type, BlockType.numbered);
    expect(b[0].items, ['first', 'second']);
    expect(b[0].toMarkdown(), '1. first\n2. second');
  });

  test('table block keeps header and rows', () {
    final b = parseBlocks('|name|due|\n|---|---|\n|essay|fri|');
    expect(b.length, 1);
    expect(b[0].type, BlockType.table);
    expect(b[0].hasHeader, isTrue);
    expect(b[0].rows[0], ['name', 'due']);
    expect(b[0].rows[1], ['essay', 'fri']);
    expect(b[0].toMarkdown(), '|name|due|\n|---|---|\n|essay|fri|');
  });

  test('divider block', () {
    final b = parseBlocks('---');
    expect(b.length, 1);
    expect(b[0].type, BlockType.divider);
    expect(b[0].toMarkdown(), '---');
  });

  test('image block keeps alt and url', () {
    final b = parseBlocks('![diagram](img/diagram.png)');
    expect(b.length, 1);
    expect(b[0].type, BlockType.image);
    expect(b[0].text, 'diagram');
    expect(b[0].url, 'img/diagram.png');
    expect(b[0].toMarkdown(), '![diagram](img/diagram.png)');
  });

  test('paragraph block keeps plain lines together', () {
    final b = parseBlocks('hello world\nsecond line');
    expect(b.length, 1);
    expect(b[0].type, BlockType.paragraph);
    expect(b[0].text, 'hello world\nsecond line');
    expect(b[0].toMarkdown(), 'hello world\nsecond line');
  });

  test('legacy plain-text body parses to one paragraph intact', () {
    final b = parseBlocks('plain text body');
    expect(b.length, 1);
    expect(b[0].type, BlockType.paragraph);
    expect(b[0].text, 'plain text body');
    expect(blocksToMarkdown(b), 'plain text body');
  });

  test('block offsets point into the body', () {
    const body = '# Title\n\n- [x] done\n\n```dart\nx\n```';
    final b = parseBlocks(body);
    expect(b.length, 3);
    expect(body.substring(b[0].start, b[0].end), '# Title');
    expect(body.substring(b[1].start, b[1].end), '- [x] done');
    expect(body.substring(b[2].start, b[2].end), '```dart\nx\n```');
  });

  test('multi-block round-trip is stable', () {
    const body =
        '# Notes\n\nSome text\n\n- [ ] todo\n\n> [!info] Tip\n> be careful\n\n|a|b|\n|---|---|\n|1|2|';
    final b = parseBlocks(body);
    expect(b.map((x) => x.type).toList(), [
      BlockType.heading,
      BlockType.paragraph,
      BlockType.todo,
      BlockType.callout,
      BlockType.table,
    ]);
    expect(blocksToMarkdown(b), body);
    final b2 = parseBlocks(blocksToMarkdown(b));
    expect(b2.map((x) => x.type).toList(), b.map((x) => x.type).toList());
  });
}
