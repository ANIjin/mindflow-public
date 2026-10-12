enum BlockType {
  heading,
  todo,
  toggle,
  callout,
  code,
  quote,
  bulleted,
  numbered,
  table,
  divider,
  image,
  paragraph,
}

class Block {
  BlockType type;
  String text;
  int level;
  bool checked;
  String lang;
  String kind;
  String url;
  List<String> items;
  List<List<String>> rows;
  bool hasHeader;
  List<Block> children;
  int start;
  int end;

  Block(this.type,
      {this.text = '',
      this.level = 1,
      this.checked = false,
      this.lang = '',
      this.kind = '',
      this.url = '',
      List<String>? items,
      List<List<String>>? rows,
      this.hasHeader = false,
      List<Block>? children,
      this.start = 0,
      this.end = 0})
      : items = items ?? [],
        rows = rows ?? [],
        children = children ?? [];

  String toMarkdown() => switch (type) {
        BlockType.heading => '${'#' * level} $text',
        BlockType.todo => '- [${checked ? 'x' : ' '}] $text',
        BlockType.toggle =>
          '> [!toggle]\n${blocksToMarkdown(children).split('\n').map((l) => l.isEmpty ? '' : '> $l').join('\n')}',
        BlockType.callout => items.isEmpty
            ? '> [!$kind]${text.isEmpty ? '' : ' $text'}'
            : '> [!$kind]${text.isEmpty ? '' : ' $text'}\n${items.map((l) => '> $l').join('\n')}',
        BlockType.code => '```$lang\n$text\n```',
        BlockType.quote =>
          text.split('\n').map((l) => '> $l').join('\n'),
        BlockType.bulleted => items.map((i) => '- $i').join('\n'),
        BlockType.numbered =>
          List.generate(items.length, (i) => '${i + 1}. ${items[i]}').join('\n'),
        BlockType.table => () {
            final out = rows.map((r) => '|${r.join('|')}|').toList();
            if (hasHeader && out.isNotEmpty) {
              out.insert(1, '|${List.filled(rows[0].length, '---').join('|')}|');
            }
            return out.join('\n');
          }(),
        BlockType.divider => '---',
        BlockType.image => '![${text}](${url})',
        BlockType.paragraph => text,
      };
}

String blocksToMarkdown(List<Block> blocks) =>
    blocks.map((b) => b.toMarkdown()).join('\n\n');

List<Block> parseBlocks(String body) {
  final lines = body.split('\n');
  final starts = List<int>.filled(lines.length, 0);
  var pos = 0;
  for (var i = 0; i < lines.length; i++) {
    starts[i] = pos;
    pos += lines[i].length + 1;
  }
  int endOf(int i) => starts[i] + lines[i].length;

  final blocks = <Block>[];
  var i = 0;
  while (i < lines.length) {
    final raw = lines[i];
    if (raw.trim().isEmpty) {
      i++;
      continue;
    }

    final fence = RegExp(r'^```(\w*)$').firstMatch(raw.trim());
    if (fence != null) {
      var j = i + 1;
      final code = <String>[];
      while (j < lines.length && lines[j].trim() != '```') {
        code.add(lines[j]);
        j++;
      }
      final last = j < lines.length ? j : j - 1;
      blocks.add(Block(BlockType.code,
          lang: fence.group(1) ?? '',
          text: code.join('\n'),
          start: starts[i],
          end: endOf(last)));
      i = j + 1;
      continue;
    }

    final co = RegExp(r'^>\s*\[!(\w+)\]\s?(.*)$').firstMatch(raw);
    if (co != null) {
      final kind = co.group(1)!.toLowerCase();
      final title = co.group(2) ?? '';
      var j = i + 1;
      final content = <String>[];
      while (j < lines.length && lines[j].startsWith('>')) {
        content.add(lines[j].replaceFirst(RegExp(r'^>\s?'), ''));
        j++;
      }
      final last = j - 1;
      final b = Block(kind == 'toggle' ? BlockType.toggle : BlockType.callout,
          kind: kind,
          text: title,
          start: starts[i],
          end: endOf(last));
      if (kind == 'toggle') {
        b.children = parseBlocks(content.join('\n'));
      } else {
        b.items = content;
      }
      blocks.add(b);
      i = j;
      continue;
    }

    if (raw.startsWith('>')) {
      var j = i;
      final content = <String>[];
      while (j < lines.length && lines[j].startsWith('>')) {
        content.add(lines[j].replaceFirst(RegExp(r'^>\s?'), ''));
        j++;
      }
      final last = j - 1;
      blocks.add(Block(BlockType.quote,
          text: content.join('\n'), start: starts[i], end: endOf(last)));
      i = j;
      continue;
    }

    if (raw.trim().startsWith('|')) {
      var j = i;
      final rows = <List<String>>[];
      var hasHeader = false;
      while (j < lines.length && lines[j].trim().startsWith('|')) {
        final cells = lines[j].trim().split('|');
        if (cells.isNotEmpty && cells.first.isEmpty) cells.removeAt(0);
        if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
        if (cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c.trim()))) {
          hasHeader = rows.isNotEmpty;
          j++;
          continue;
        }
        rows.add(cells.map((c) => c.trim()).toList());
        j++;
      }
      final last = j - 1;
      blocks.add(Block(BlockType.table,
          rows: rows,
          hasHeader: hasHeader,
          start: starts[i],
          end: endOf(last)));
      i = j;
      continue;
    }

    if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(raw.trim())) {
      blocks.add(Block(BlockType.divider, start: starts[i], end: endOf(i)));
      i++;
      continue;
    }

    final img = RegExp(r'^!\[([^\]]*)\]\(([^)]*)\)$').firstMatch(raw.trim());
    if (img != null) {
      blocks.add(Block(BlockType.image,
          text: img.group(1) ?? '',
          url: img.group(2) ?? '',
          start: starts[i],
          end: endOf(i)));
      i++;
      continue;
    }

    final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(raw);
    if (h != null) {
      final lvl = h.group(1)!.length > 3 ? 3 : h.group(1)!.length;
      blocks.add(Block(BlockType.heading,
          level: lvl,
          text: h.group(2) ?? '',
          start: starts[i],
          end: endOf(i)));
      i++;
      continue;
    }

    final td = RegExp(r'^-\s*\[( |x|X)\]\s+(.*)$').firstMatch(raw);
    if (td != null) {
      blocks.add(Block(BlockType.todo,
          checked: td.group(1)!.toLowerCase() == 'x',
          text: td.group(2) ?? '',
          start: starts[i],
          end: endOf(i)));
      i++;
      continue;
    }

    if (RegExp(r'^-\s+.+$').hasMatch(raw) &&
        !RegExp(r'^-\s*\[( |x|X)\]').hasMatch(raw)) {
      var j = i;
      final items = <String>[];
      while (j < lines.length &&
          RegExp(r'^-\s+.+$').hasMatch(lines[j]) &&
          !RegExp(r'^-\s*\[( |x|X)\]').hasMatch(lines[j])) {
        items.add(lines[j].replaceFirst(RegExp(r'^-\s+'), ''));
        j++;
      }
      final last = j - 1;
      blocks.add(Block(BlockType.bulleted,
          items: items, start: starts[i], end: endOf(last)));
      i = j;
      continue;
    }

    if (RegExp(r'^\d+\.\s+.+$').hasMatch(raw)) {
      var j = i;
      final items = <String>[];
      while (j < lines.length && RegExp(r'^\d+\.\s+.+$').hasMatch(lines[j])) {
        items.add(lines[j].replaceFirst(RegExp(r'^\d+\.\s+'), ''));
        j++;
      }
      final last = j - 1;
      blocks.add(Block(BlockType.numbered,
          items: items, start: starts[i], end: endOf(last)));
      i = j;
      continue;
    }

    var j = i;
    final para = <String>[];
    while (j < lines.length &&
        lines[j].trim().isNotEmpty &&
        !_isBlockStart(lines[j])) {
      para.add(lines[j]);
      j++;
    }
    final last = j - 1;
    blocks.add(Block(BlockType.paragraph,
        text: para.join('\n'), start: starts[i], end: endOf(last)));
    i = j;
    continue;
  }
  return blocks;
}

bool _isBlockStart(String line) {
  final t = line.trim();
  if (t.isEmpty) return true;
  return t.startsWith('```') ||
      line.startsWith('>') ||
      t.startsWith('|') ||
      RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(t) ||
      RegExp(r'^!\[([^\]]*)\]\(([^)]*)\)$').hasMatch(t) ||
      RegExp(r'^#{1,6}\s+.+$').hasMatch(line) ||
      RegExp(r'^-\s*\[( |x|X)\]\s+.+$').hasMatch(line) ||
      RegExp(r'^-\s+.+$').hasMatch(line) ||
      RegExp(r'^\d+\.\s+.+$').hasMatch(line);
}
