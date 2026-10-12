import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/models/blocks.dart';
import '../../core/models/node.dart';
import '../shell_state.dart';
import '../tokens.dart';
import 'apple.dart';

typedef PageOpenCallback = void Function(String id);

/// Markdown-first block editor bound to [parseBlocks] / [blocksToMarkdown].
class PageEditor extends StatefulWidget {
  final MindNode node;
  final FocusNode? focusNode;
  final PageOpenCallback? onOpenPage;
  final ValueChanged<String>? onTagTap;

  const PageEditor({
    super.key,
    required this.node,
    this.focusNode,
    this.onOpenPage,
    this.onTagTap,
  });

  @override
  State<PageEditor> createState() => PageEditorState();
}

class PageEditorState extends State<PageEditor> {
  late List<Block> _blocks;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  Timer? _autosave;
  String _saveStatus = 'Saved';
  bool _showPreview = true;
  int? _slashAt;
  String _slashQuery = '';
  int? _wikiAt;
  String _wikiQuery = '';
  int? _tagAt;
  String _tagQuery = '';
  final Set<int> _collapsedToggles = {};
  AppState? _app;
  String _preview = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = context.read<AppState>();
  }

  @override
  void initState() {
    super.initState();
    _loadFromNode();
  }

  @override
  void didUpdateWidget(covariant PageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      unawaited(_flushSave());
      _loadFromNode();
    }
  }

  void _loadFromNode() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _blocks = parseBlocks(widget.node.body);
    if (_blocks.isEmpty) {
      _blocks = [Block(BlockType.paragraph, text: '')];
    }
    for (var i = 0; i < _blocks.length; i++) {
      _ensureControllers(i);
    }
    _preview = blocksToMarkdown(_blocks);
    _saveStatus = 'Saved';
    _slashAt = null;
    _wikiAt = null;
    _tagAt = null;
    setState(() {});
  }

  void _ensureControllers(int i) {
    final b = _blocks[i];
    final text = switch (b.type) {
      BlockType.bulleted || BlockType.numbered => b.items.join('\n'),
      BlockType.callout => [if (b.text.isNotEmpty) b.text, ...b.items].join('\n'),
      BlockType.table =>
        b.rows.map((r) => r.join(' | ')).join('\n'),
      _ => b.text,
    };
    _controllers.putIfAbsent(i, () => TextEditingController(text: text));
    _focusNodes.putIfAbsent(i, () => FocusNode(debugLabel: 'block-$i'));
    if (_controllers[i]!.text != text) {
      _controllers[i]!.text = text;
    }
  }

  void reindexControllers() {
    final texts = <int, String>{};
    for (final e in _controllers.entries) {
      texts[e.key] = e.value.text;
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    for (var i = 0; i < _blocks.length; i++) {
      _ensureControllers(i);
      if (texts.containsKey(i)) {
        // keep if still meaningful after reorder handled separately
      }
    }
  }

  @override
  void dispose() {
    _autosave?.cancel();
    // Persist best-effort without touching the element tree.
    _syncBlocksFromControllers();
    final md = blocksToMarkdown(_blocks);
    final app = _app;
    if (app != null && md != widget.node.body) {
      widget.node.body = md;
      unawaited(app.saveNode(widget.node));
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void focusEditor() {
    if (_focusNodes.isEmpty) return;
    _focusNodes[0]?.requestFocus();
  }

  void _scheduleSave() {
    _syncBlocksFromControllers();
    // Avoid feeding incomplete slash/wiki drafts into flutter_markdown.
    if (_slashAt == null && _wikiAt == null && _tagAt == null) {
      _preview = blocksToMarkdown(_blocks);
    }
    setState(() => _saveStatus = 'Saving…');
    _autosave?.cancel();
    _autosave = Timer(const Duration(seconds: 2), () {
      unawaited(_flushSave());
    });
  }

  Future<void> _flushSave() async {
    _autosave?.cancel();
    _syncBlocksFromControllers();
    final md = blocksToMarkdown(_blocks);
    _preview = md;
    if (md == widget.node.body) {
      if (mounted) setState(() => _saveStatus = 'Saved');
      return;
    }
    widget.node.body = md;
    final app = _app ?? (mounted ? context.read<AppState>() : null);
    if (app == null) return;
    await app.saveNode(widget.node);
    if (mounted) setState(() => _saveStatus = 'Saved');
  }

  void _syncBlocksFromControllers() {
    for (var i = 0; i < _blocks.length; i++) {
      final c = _controllers[i];
      if (c == null) continue;
      final b = _blocks[i];
      switch (b.type) {
        case BlockType.bulleted:
        case BlockType.numbered:
          b.items = c.text
              .split('\n')
              .map((e) => e.trimRight())
              .where((e) => e.isNotEmpty)
              .toList();
        case BlockType.callout:
          final lines = c.text.split('\n');
          b.text = lines.isNotEmpty ? lines.first : '';
          b.items = lines.length > 1 ? lines.sublist(1) : [];
        case BlockType.table:
          b.rows = c.text
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .map((l) => l.split('|').map((c) => c.trim()).toList())
              .toList();
          b.hasHeader = b.rows.isNotEmpty;
        default:
          b.text = c.text;
      }
    }
  }

  String get previewMarkdown => _preview;

  void _onChanged(int index, String value) {
    final b = _blocks[index];
    // Slash menu on empty paragraph starting with /
    if (b.type == BlockType.paragraph ||
        b.type == BlockType.heading ||
        b.type == BlockType.quote) {
      if (value.startsWith('/') && !value.contains('\n')) {
        setState(() {
          _slashAt = index;
          _slashQuery = value.substring(1);
          _wikiAt = null;
          _tagAt = null;
        });
      } else if (_slashAt == index) {
        setState(() => _slashAt = null);
      }

      final wiki = RegExp(r'\[\[([^\]]*)$').firstMatch(value);
      if (wiki != null) {
        setState(() {
          _wikiAt = index;
          _wikiQuery = wiki.group(1) ?? '';
          _slashAt = null;
          _tagAt = null;
        });
      } else if (_wikiAt == index) {
        setState(() => _wikiAt = null);
      }

      final tag = RegExp(r'(^|[\s])#([A-Za-z0-9_\-]*)$').firstMatch(value);
      if (tag != null) {
        setState(() {
          _tagAt = index;
          _tagQuery = (tag.group(2) ?? '').toLowerCase();
          _slashAt = null;
          _wikiAt = null;
        });
      } else if (_tagAt == index) {
        setState(() => _tagAt = null);
      }
    }
    _scheduleSave();
  }

  void _insertBlockType(int index, BlockType type, {String? seed}) {
    _syncBlocksFromControllers();
    final block = switch (type) {
      BlockType.heading => Block(BlockType.heading, text: seed ?? '', level: 1),
      BlockType.todo => Block(BlockType.todo, text: seed ?? ' '),
      BlockType.toggle => Block(BlockType.toggle, children: [
          Block(BlockType.paragraph, text: '')
        ]),
      BlockType.callout =>
        Block(BlockType.callout, kind: 'note', text: seed ?? ''),
      BlockType.code => Block(BlockType.code, lang: 'dart', text: seed ?? ''),
      BlockType.quote => Block(BlockType.quote, text: seed ?? ''),
      BlockType.bulleted =>
        Block(BlockType.bulleted, items: [if ((seed ?? '').isNotEmpty) seed!]),
      BlockType.numbered =>
        Block(BlockType.numbered, items: [if ((seed ?? '').isNotEmpty) seed!]),
      BlockType.table => Block(BlockType.table, hasHeader: true, rows: [
          ['Column 1', 'Column 2'],
          ['', ''],
        ]),
      BlockType.divider => Block(BlockType.divider),
      BlockType.image => Block(BlockType.image, text: 'image', url: ''),
      BlockType.paragraph => Block(BlockType.paragraph, text: seed ?? ''),
    };
    setState(() {
      _blocks[index] = block;
      _slashAt = null;
      _slashQuery = '';
      _controllers[index]?.dispose();
      _controllers.remove(index);
      _ensureControllers(index);
      _preview = blocksToMarkdown(_blocks);
    });
    _scheduleSave();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[index]?.requestFocus();
    });
  }

  void _insertWikilink(int index, String title) {
    final c = _controllers[index]!;
    final text = c.text;
    final m = RegExp(r'\[\[[^\]]*$').firstMatch(text);
    if (m == null) return;
    final next = '${text.substring(0, m.start)}[[$title]]';
    c.text = next;
    c.selection = TextSelection.collapsed(offset: next.length);
    setState(() => _wikiAt = null);
    _scheduleSave();
  }

  void _insertTag(int index, String tag) {
    final c = _controllers[index]!;
    final text = c.text;
    final m = RegExp(r'#[A-Za-z0-9_\-]*$').firstMatch(text);
    if (m == null) return;
    final next = '${text.substring(0, m.start)}#$tag';
    c.text = next;
    c.selection = TextSelection.collapsed(offset: next.length);
    setState(() => _tagAt = null);
    _scheduleSave();
  }

  void _reorder(int oldIndex, int newIndex) {
    _syncBlocksFromControllers();
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
      // Rebuild controllers from blocks
      for (final c in _controllers.values) {
        c.dispose();
      }
      for (final f in _focusNodes.values) {
        f.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();
      for (var i = 0; i < _blocks.length; i++) {
        _ensureControllers(i);
      }
    });
    _scheduleSave();
  }

  /// Test helper: reorder blocks programmatically.
  @visibleForTesting
  void debugReorder(int oldIndex, int newIndex) => _reorder(oldIndex, newIndex);

  /// Test helper: force flush autosave.
  @visibleForTesting
  Future<void> debugFlushSave() => _flushSave();

  void _addBlockAfter(int index) {
    _syncBlocksFromControllers();
    setState(() {
      _blocks.insert(index + 1, Block(BlockType.paragraph, text: ''));
      for (final c in _controllers.values) {
        c.dispose();
      }
      for (final f in _focusNodes.values) {
        f.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();
      for (var i = 0; i < _blocks.length; i++) {
        _ensureControllers(i);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[index + 1]?.requestFocus();
    });
    _scheduleSave();
  }

  List<(BlockType, String, String)> get _slashItems => const [
        (BlockType.heading, 'Heading', 'h1 title heading'),
        (BlockType.todo, 'To-do', 'todo checkbox task'),
        (BlockType.toggle, 'Toggle', 'collapse toggle'),
        (BlockType.callout, 'Callout', 'note tip callout'),
        (BlockType.code, 'Code', 'snippet code'),
        (BlockType.quote, 'Quote', 'blockquote quote'),
        (BlockType.bulleted, 'Bulleted list', 'ul bullet'),
        (BlockType.numbered, 'Numbered list', 'ol numbered'),
        (BlockType.table, 'Table', 'tab table grid'),
        (BlockType.divider, 'Divider', 'line hr divider'),
        (BlockType.image, 'Image', 'pic image'),
        (BlockType.paragraph, 'Paragraph', 'text paragraph'),
      ];

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final state = context.watch<AppState>();
    final titles = state.store.nodes.values.map((n) => n.title).where((x) => x.isNotEmpty).toList()
      ..sort();
    final tags = <String>{};
    for (final n in state.store.nodes.values) {
      tags.addAll(n.tags);
      tags.addAll(
          RegExp(r'#([A-Za-z0-9_\-]+)').allMatches(n.body).map((m) => m.group(1)!.toLowerCase()));
    }
    final tagList = tags.toList()..sort();

    return Column(
      key: const ValueKey('page-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(t.lg, t.sm, t.lg, t.sm),
          child: Row(
            children: [
              Text(_saveStatus,
                  key: const ValueKey('save-indicator'),
                  style: TextStyle(fontSize: t.textSmall, color: t.secondary)),
              const Spacer(),
              AppleIconButton(
                key: const ValueKey('toggle-preview'),
                icon: _showPreview
                    ? CupertinoIcons.eye_slash
                    : CupertinoIcons.eye,
                onPressed: () => setState(() => _showPreview = !_showPreview),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  key: const ValueKey('block-list'),
                  padding: EdgeInsets.fromLTRB(t.md, 0, t.md, t.lg),
                  itemCount: _blocks.length,
                  onReorder: _reorder,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    return _blockTile(context, t, index);
                  },
                ),
              ),
              if (_showPreview) ...[
                Container(width: 1, color: t.hairline),
                Expanded(
                  child: _MarkdownPreview(data: _preview, tokens: t),
                ),
              ],
            ],
          ),
        ),
        if (_slashAt != null) _slashMenu(t),
        if (_wikiAt != null) _wikiMenu(t, titles),
        if (_tagAt != null) _tagMenu(t, tagList),
      ],
    );
  }

  Widget _slashMenu(Tokens t) {
    final q = _slashQuery.toLowerCase();
    final items = _slashItems
        .where((e) =>
            q.isEmpty ||
            e.$2.toLowerCase().contains(q) ||
            e.$3.toLowerCase().contains(q))
        .toList();
    return Material(
      color: t.card,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          key: const ValueKey('slash-menu'),
          shrinkWrap: true,
          children: [
            for (final item in items)
              ListTile(
                key: ValueKey('slash-${item.$1.name}'),
                dense: true,
                title: Text(item.$2),
                onTap: () => _insertBlockType(_slashAt!, item.$1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wikiMenu(Tokens t, List<String> titles) {
    final q = _wikiQuery.toLowerCase();
    final matches = titles
        .where((title) => q.isEmpty || title.toLowerCase().contains(q))
        .take(8)
        .toList();
    final unresolved = q.isNotEmpty &&
        !titles.any((title) => title.toLowerCase() == q);
    return Material(
      color: t.card,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          key: const ValueKey('wiki-menu'),
          shrinkWrap: true,
          children: [
            for (final title in matches)
              ListTile(
                dense: true,
                title: Text(title),
                onTap: () => _insertWikilink(_wikiAt!, title),
              ),
            if (unresolved)
              ListTile(
                key: const ValueKey('wiki-create'),
                dense: true,
                title: Text('Create "$q"'),
                onTap: () async {
                  final state = context.read<AppState>();
                  final shell = context.read<ShellState>();
                  final n = MindNode(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _wikiQuery);
                  await state.saveNode(n);
                  _insertWikilink(_wikiAt!, n.title);
                  shell.openPage(n.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _tagMenu(Tokens t, List<String> tags) {
    final q = _tagQuery;
    final matches =
        tags.where((tag) => q.isEmpty || tag.contains(q)).take(8).toList();
    return Material(
      color: t.card,
      elevation: 8,
      child: ListView(
        key: const ValueKey('tag-menu'),
        shrinkWrap: true,
        children: [
          for (final tag in matches)
            ListTile(
              dense: true,
              title: Text('#$tag'),
              onTap: () => _insertTag(_tagAt!, tag),
            ),
        ],
      ),
    );
  }

  Widget _blockTile(BuildContext context, Tokens t, int index) {
    final b = _blocks[index];
    final focus = widget.focusNode != null && index == 0
        ? widget.focusNode!
        : _focusNodes[index]!;

    Widget body;
    switch (b.type) {
      case BlockType.divider:
        body = Divider(key: ValueKey('block-divider-$index'), color: t.hairline);
      case BlockType.todo:
        body = Row(
          children: [
            Checkbox(
              key: ValueKey('todo-check-$index'),
              value: b.checked,
              onChanged: (v) {
                setState(() => b.checked = v ?? false);
                _scheduleSave();
              },
            ),
            Expanded(
              child: TextField(
                key: ValueKey('block-field-$index'),
                controller: _controllers[index],
                focusNode: focus,
                onChanged: (v) => _onChanged(index, v),
                onSubmitted: (_) => _addBlockAfter(index),
                style: TextStyle(
                  decoration: b.checked ? TextDecoration.lineThrough : null,
                  color: t.label,
                ),
                decoration: const InputDecoration(
                    border: InputBorder.none, filled: false),
              ),
            ),
          ],
        );
      case BlockType.toggle:
        final collapsed = _collapsedToggles.contains(index);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() {
                if (collapsed) {
                  _collapsedToggles.remove(index);
                } else {
                  _collapsedToggles.add(index);
                }
              }),
              child: Row(
                children: [
                  Icon(
                    collapsed
                        ? CupertinoIcons.chevron_right
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: t.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text('Toggle',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: t.label)),
                ],
              ),
            ),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: TextField(
                  key: ValueKey('block-field-$index'),
                  controller: _controllers[index],
                  focusNode: focus,
                  maxLines: null,
                  onChanged: (v) {
                    b.children = [Block(BlockType.paragraph, text: v)];
                    _onChanged(index, v);
                  },
                  decoration: const InputDecoration(
                      border: InputBorder.none, filled: false),
                ),
              ),
          ],
        );
      case BlockType.callout:
        body = Container(
          padding: EdgeInsets.all(t.sm),
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.accent.withValues(alpha: 0.25)),
          ),
          child: TextField(
            key: ValueKey('block-field-$index'),
            controller: _controllers[index],
            focusNode: focus,
            maxLines: null,
            onChanged: (v) => _onChanged(index, v),
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: false,
              prefixText: '${b.kind.isEmpty ? 'note' : b.kind}: ',
            ),
          ),
        );
      case BlockType.code:
        body = Container(
          padding: EdgeInsets.all(t.sm),
          decoration: BoxDecoration(
            color: t.elevated,
            borderRadius: BorderRadius.circular(t.radiusMd),
          ),
          child: TextField(
            key: ValueKey('block-field-$index'),
            controller: _controllers[index],
            focusNode: focus,
            maxLines: null,
            style: TextStyle(
                fontFamily: 'Consolas', fontSize: t.textSmall, color: t.label),
            onChanged: (v) => _onChanged(index, v),
            decoration: InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: 'code (${b.lang})',
            ),
          ),
        );
      case BlockType.quote:
        body = Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: t.accent, width: 3)),
          ),
          padding: const EdgeInsets.only(left: 10),
          child: TextField(
            key: ValueKey('block-field-$index'),
            controller: _controllers[index],
            focusNode: focus,
            maxLines: null,
            style: TextStyle(
                fontStyle: FontStyle.italic, color: t.secondary),
            onChanged: (v) => _onChanged(index, v),
            decoration: const InputDecoration(
                border: InputBorder.none, filled: false),
          ),
        );
      case BlockType.heading:
        body = TextField(
          key: ValueKey('block-field-$index'),
          controller: _controllers[index],
          focusNode: focus,
          onChanged: (v) => _onChanged(index, v),
          onSubmitted: (_) => _addBlockAfter(index),
          style: TextStyle(
            fontSize: b.level == 1
                ? t.textTitle
                : b.level == 2
                    ? t.textHead
                    : t.textBody + 2,
            fontWeight: FontWeight.w700,
            color: t.label,
          ),
          decoration: const InputDecoration(
              border: InputBorder.none, filled: false, hintText: 'Heading'),
        );
      case BlockType.image:
        body = Row(
          children: [
            Icon(CupertinoIcons.photo, color: t.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: ValueKey('block-field-$index'),
                controller: _controllers[index],
                focusNode: focus,
                onChanged: (v) {
                  b.text = v;
                  _onChanged(index, v);
                },
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    hintText: 'Image alt text'),
              ),
            ),
          ],
        );
      default:
        body = TextField(
          key: ValueKey('block-field-$index'),
          controller: _controllers[index],
          focusNode: focus,
          maxLines: null,
          onChanged: (v) => _onChanged(index, v),
          onSubmitted: (_) => _addBlockAfter(index),
          style: TextStyle(fontSize: t.textBody, color: t.label, height: 1.5),
          decoration: const InputDecoration(
              border: InputBorder.none, filled: false, hintText: 'Type / for commands'),
        );
    }

    return Material(
      key: ValueKey('block-$index-${b.type.name}'),
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 4),
                child: Icon(CupertinoIcons.line_horizontal_3,
                    key: ValueKey('drag-$index'),
                    size: 14,
                    color: t.tertiary),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _MarkdownPreview extends StatelessWidget {
  final String data;
  final Tokens tokens;
  const _MarkdownPreview({required this.data, required this.tokens});

  /// flutter_markdown asserts on some GFM checkbox edge cases; normalize them.
  static String sanitize(String md) {
    if (md.trim().isEmpty) return ' ';
    return md
        .replaceAllMapped(
            RegExp(r'^- \[([ xX])\] ?(.*)$', multiLine: true),
            (m) =>
                '- ${m.group(1)!.toLowerCase() == 'x' ? '☑' : '☐'} ${m.group(2) ?? ''}')
        .replaceAllMapped(
            RegExp(r'^> \[!(\w+)\] ?(.*)$', multiLine: true),
            (m) => '> **${m.group(1)}** ${m.group(2) ?? ''}');
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final md = sanitize(data);
    return Markdown(
      key: const ValueKey('markdown-preview'),
      data: md,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        h1: TextStyle(
            fontSize: t.textTitle,
            fontWeight: FontWeight.w700,
            color: t.label),
        h2: TextStyle(
            fontSize: t.textHead,
            fontWeight: FontWeight.w700,
            color: t.label),
        h3: TextStyle(
            fontSize: t.textBody + 2,
            fontWeight: FontWeight.w600,
            color: t.label),
        p: TextStyle(fontSize: t.textBody, color: t.label, height: 1.5),
        code: TextStyle(
            fontFamily: 'Consolas',
            fontSize: t.textSmall,
            color: t.accent,
            backgroundColor: t.elevated),
        blockquote:
            TextStyle(color: t.secondary, fontStyle: FontStyle.italic),
      ),
    );
  }
}
