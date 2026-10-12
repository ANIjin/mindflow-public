import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app_state.dart';
import '../../core/models/node.dart';
import '../shell_state.dart';
import '../tokens.dart';

class PaletteCommand {
  final String id;
  final String label;
  final String keywords;
  final VoidCallback run;
  const PaletteCommand({
    required this.id,
    required this.label,
    required this.keywords,
    required this.run,
  });
}

class CommandPaletteOverlay extends StatefulWidget {
  const CommandPaletteOverlay({super.key});

  @override
  State<CommandPaletteOverlay> createState() => _CommandPaletteOverlayState();
}

class _CommandPaletteOverlayState extends State<CommandPaletteOverlay> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<PaletteCommand> _commands(BuildContext context) {
    final shell = context.read<ShellState>();
    final state = context.read<AppState>();
    return [
      PaletteCommand(
        id: 'new-page',
        label: 'New page',
        keywords: 'create page note',
        run: () {
          final n = MindNode(id: const Uuid().v4(), title: 'Untitled');
          state.saveNode(n);
          shell.openPage(n.id);
        },
      ),
      PaletteCommand(
        id: 'search',
        label: 'Search pages',
        keywords: 'find query',
        run: () => shell.openSearch(),
      ),
      PaletteCommand(
        id: 'toggle-sidebar',
        label: 'Toggle sidebar',
        keywords: 'collapse expand rail',
        run: () => shell.toggleSidebar(),
      ),
      PaletteCommand(
        id: 'board',
        label: 'Open board',
        keywords: 'views database',
        run: () => shell.setDestination(ShellDestination.board),
      ),
      PaletteCommand(
        id: 'calendar',
        label: 'Open calendar',
        keywords: 'schedule',
        run: () => shell.setDestination(ShellDestination.calendar),
      ),
      PaletteCommand(
        id: 'chat',
        label: 'Open chat',
        keywords: 'agent ask',
        run: () => shell.setDestination(ShellDestination.chat),
      ),
      PaletteCommand(
        id: 'memory',
        label: 'Open memory',
        keywords: 'vault log',
        run: () => shell.setDestination(ShellDestination.memory),
      ),
      PaletteCommand(
        id: 'settings',
        label: 'Open settings',
        keywords: 'prefs theme',
        run: () => shell.setDestination(ShellDestination.settings),
      ),
      PaletteCommand(
        id: 'sync',
        label: 'Run sync',
        keywords: 'integrations refresh',
        run: () {
          state.syncNow();
        },
      ),
      PaletteCommand(
        id: 'daily',
        label: 'Open daily note',
        keywords: 'today journal daily',
        run: () {
          final today = DateTime.now();
          final title =
              'Daily ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final existing = state.store.nodes.values
              .where((n) => n.title == title)
              .toList();
          if (existing.isNotEmpty) {
            shell.openPage(existing.first.id);
            return;
          }
          final n = MindNode(
            id: const Uuid().v4(),
            title: title,
            type: 'daily',
            body: '# $title\n\n## Classes\n\n## Due today\n\n',
            spaceId: 'Daily',
          );
          state.saveNode(n);
          shell.openPage(n.id);
        },
      ),
      PaletteCommand(
        id: 'graph',
        label: 'Open graph',
        keywords: 'links network',
        run: () => shell.setDestination(ShellDestination.graph),
      ),
      PaletteCommand(
        id: 'quick-capture',
        label: 'Quick capture',
        keywords: 'inbox capture thought',
        run: () => shell.openQuickCapture(),
      ),
    ];
  }

  List<PaletteCommand> _filtered(BuildContext context) {
    final q = _controller.text.trim().toLowerCase();
    final all = _commands(context);
    if (q.isEmpty) return all;
    return all
        .where((c) =>
            c.label.toLowerCase().contains(q) ||
            c.keywords.toLowerCase().contains(q) ||
            c.id.contains(q))
        .toList();
  }

  List<PaletteCommand> _searchFallback(BuildContext context) {
    final q = _controller.text.trim();
    if (q.isEmpty) return const [];
    final state = context.read<AppState>();
    final shell = context.read<ShellState>();
    final hits = state.store.searchIndex.search(q, state.store.nodes);
    return [
      for (final h in hits.take(8))
        PaletteCommand(
          id: 'search-${h.nodeId}',
          label:
              'Open ${state.store.nodes[h.nodeId]?.title ?? h.nodeId}: ${h.snippet}',
          keywords: 'content search',
          run: () {
            shell.openPage(h.nodeId);
          },
        ),
    ];
  }

  void _execute(BuildContext context, PaletteCommand cmd) {
    final shell = context.read<ShellState>();
    shell.closePalette();
    cmd.run();
  }

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final shell = context.watch<ShellState>();
    if (!shell.paletteOpen) return const SizedBox.shrink();

    final matches = _filtered(context);
    final searchHits = matches.isEmpty ? _searchFallback(context) : const <PaletteCommand>[];
    final rows = matches.isEmpty ? searchHits : matches;
    if (_selected >= rows.length) _selected = 0;

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: GestureDetector(
        onTap: () => shell.closePalette(),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
              child: Material(
                key: const ValueKey('command-palette'),
                color: t.card,
                elevation: 24,
                borderRadius: BorderRadius.circular(t.radiusLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(t.md, t.md, t.md, t.sm),
                      child: TextField(
                        key: const ValueKey('palette-input'),
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: (_) => setState(() => _selected = 0),
                        onSubmitted: (_) {
                          if (rows.isNotEmpty) {
                            _execute(context, rows[_selected]);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Type a command or search…',
                          prefixIcon: Icon(CupertinoIcons.search,
                              size: 18, color: t.secondary),
                          border: InputBorder.none,
                          filled: false,
                        ),
                        style: TextStyle(fontSize: t.textBody, color: t.label),
                      ),
                    ),
                    Divider(height: 1, color: t.hairline),
                    Flexible(
                      child: rows.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(t.lg),
                              child: Text(
                                'No commands match. Search page content instead.',
                                key: const ValueKey('palette-empty'),
                                style: TextStyle(color: t.secondary),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: rows.length,
                              itemBuilder: (context, i) {
                                final c = rows[i];
                                final selected = i == _selected;
                                return InkWell(
                                  key: ValueKey('palette-cmd-${c.id}'),
                                  onTap: () => _execute(context, c),
                                  onHover: (_) => setState(() => _selected = i),
                                  focusColor: t.focusRing.withValues(alpha: 0.3),
                                  child: Container(
                                    color: selected
                                        ? t.accent.withValues(alpha: 0.12)
                                        : null,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: t.md, vertical: t.sm + 2),
                                    child: Text(
                                      c.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: t.label,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
