import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../core/models/node.dart';
import 'board_page.dart';
import 'calendar_page.dart';
import 'chat_page.dart';
import 'graph_page.dart';
import 'memory_page.dart';
import 'settings_page.dart';
import 'shell_state.dart';
import 'tokens.dart';
import 'widgets/apple.dart';
import 'widgets/command_palette.dart';
import 'widgets/link_panels.dart';
import 'widgets/page_editor.dart';
import 'widgets/quick_capture.dart';
import 'widgets/sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _editorFocus = FocusNode(debugLabel: 'page-editor');

  static const _dests = <(IconData, String, ShellDestination)>[
    (CupertinoIcons.square_grid_2x2, 'Board', ShellDestination.board),
    (CupertinoIcons.calendar, 'Calendar', ShellDestination.calendar),
    (CupertinoIcons.chat_bubble, 'Chat', ShellDestination.chat),
    (CupertinoIcons.lightbulb, 'Memory', ShellDestination.memory),
    (CupertinoIcons.circle_grid_hex, 'Graph', ShellDestination.graph),
    (CupertinoIcons.gear, 'Settings', ShellDestination.settings),
  ];

  @override
  void dispose() {
    _editorFocus.dispose();
    super.dispose();
  }

  void _newPage(AppState state, ShellState shell) {
    final n = MindNode(id: const Uuid().v4(), title: 'Untitled');
    state.saveNode(n);
    shell.openPage(n.id);
  }

  Widget _content(ShellState shell) {
    switch (shell.destination) {
      case ShellDestination.board:
        return const BoardPage(key: ValueKey('page-board'));
      case ShellDestination.calendar:
        return const CalendarPage(key: ValueKey('page-calendar'));
      case ShellDestination.chat:
        return const ChatPage(key: ValueKey('page-chat'));
      case ShellDestination.memory:
        return const MemoryPage(key: ValueKey('page-memory'));
      case ShellDestination.graph:
        return const GraphViewPage(key: ValueKey('page-graph'));
      case ShellDestination.settings:
        return const SettingsPage(key: ValueKey('page-settings'));
      case ShellDestination.page:
        return _PagePane(key: ValueKey('page-node-${shell.currentPage}'), focusNode: _editorFocus);
    }
  }

  Widget _sidebarBody(AppState state, ShellState shell, Tokens t,
      {required bool compact}) {
    final name = (state.store.settings['userName'] as String?)?.trim() ?? '';
    final initials = name.isEmpty
        ? 'M'
        : name.split(RegExp(r'\s+')).map((w) => w[0]).join().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(compact ? 6 : 20, 20, compact ? 6 : 20, 12),
          child: Row(
            children: [
              const BrandMark(),
              if (!compact) ...[
                const SizedBox(width: 10),
                Text('MindFlow',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: t.label)),
              ],
              const Spacer(),
              AppleIconButton(
                key: const ValueKey('sidebar-toggle'),
                icon: shell.sidebarCollapsed
                    ? CupertinoIcons.chevron_right
                    : CupertinoIcons.chevron_left,
                box: 28,
                onPressed: shell.toggleSidebar,
              ),
            ],
          ),
        ),
        for (final d in _dests)
          SidebarItem(
            key: ValueKey('dest-${d.$3.name}'),
            icon: d.$1,
            label: d.$2,
            selected: shell.destination == d.$3,
            compact: compact,
            onTap: () => shell.setDestination(d.$3),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(compact ? 8 : 22, 12, 8, 4),
          child: compact
              ? const SizedBox.shrink()
              : Text('PAGES',
                  style: TextStyle(
                      fontSize: t.textTiny,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: t.tertiary)),
        ),
        Expanded(child: SidebarNav(store: state.store)),
        Padding(
          padding: EdgeInsets.fromLTRB(compact ? 6 : 20, 0, compact ? 6 : 20, 20),
          child: Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(initials,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: t.accent)),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'You' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: t.label)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: state.busy ? t.orange : t.green,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(state.busy ? 'Working…' : 'Ready',
                              style:
                                  TextStyle(fontSize: 11, color: t.secondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shell = context.watch<ShellState>();
    final t = tk(context);
    final wide = MediaQuery.sizeOf(context).width >= shellWideBreakpoint;
    final compact = shell.sidebarCollapsed;

    // Honor focus-editor shortcut requests.
    if (shell.focusEditorTick > 0 && shell.destination == ShellDestination.page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editorFocus.requestFocus();
      });
    }

    final content = AnimatedSwitcher(
      duration: t.normal,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: _content(shell),
    );

    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          const _OpenPaletteIntent(),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
          const _OpenPaletteIntent(),
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          const _NewPageIntent(),
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
          const _NewPageIntent(),
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          const _SearchIntent(),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
          const _SearchIntent(),
      const SingleActivator(LogicalKeyboardKey.backslash, control: true):
          const _ToggleSidebarIntent(),
      const SingleActivator(LogicalKeyboardKey.backslash, meta: true):
          const _ToggleSidebarIntent(),
      const SingleActivator(LogicalKeyboardKey.keyE, control: true):
          const _FocusEditorIntent(),
      const SingleActivator(LogicalKeyboardKey.keyE, meta: true):
          const _FocusEditorIntent(),
      const SingleActivator(LogicalKeyboardKey.space, control: true, shift: true):
          const _QuickCaptureIntent(),
      const SingleActivator(LogicalKeyboardKey.space, meta: true, shift: true):
          const _QuickCaptureIntent(),
    };

    final actions = <Type, Action<Intent>>{
      _OpenPaletteIntent: CallbackAction<_OpenPaletteIntent>(
          onInvoke: (_) {
            shell.openPalette();
            return null;
          }),
      _NewPageIntent: CallbackAction<_NewPageIntent>(
          onInvoke: (_) {
            _newPage(state, shell);
            return null;
          }),
      _SearchIntent: CallbackAction<_SearchIntent>(
          onInvoke: (_) {
            shell.openSearch();
            return null;
          }),
      _ToggleSidebarIntent: CallbackAction<_ToggleSidebarIntent>(
          onInvoke: (_) {
            if (wide) {
              shell.toggleSidebar();
            } else {
              final s = _scaffoldKey.currentState;
              if (s?.isDrawerOpen ?? false) {
                Navigator.of(context).maybePop();
              } else {
                s?.openDrawer();
              }
            }
            return null;
          }),
      _FocusEditorIntent: CallbackAction<_FocusEditorIntent>(
          onInvoke: (_) {
            shell.requestFocusEditor();
            _editorFocus.requestFocus();
            return null;
          }),
      _QuickCaptureIntent: CallbackAction<_QuickCaptureIntent>(
          onInvoke: (_) {
            shell.openQuickCapture();
            return null;
          }),
    };

    final scaffold = Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              key: const ValueKey('shell-drawer'),
              backgroundColor: t.card,
              child: SafeArea(
                child: _sidebarBody(state, shell, t, compact: false),
              ),
            ),
      body: wide
          ? Row(
              key: const ValueKey('shell-wide'),
              children: [
                AnimatedContainer(
                  key: ValueKey(compact ? 'icon-rail' : 'sidebar-full'),
                  duration: t.fast,
                  width: compact ? 72 : 248,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [t.card, t.bg],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: _sidebarBody(state, shell, t, compact: compact),
                ),
                Container(width: 1, color: t.hairline),
                Expanded(child: content),
              ],
            )
          : SafeArea(
              bottom: false,
              child: Column(
                key: const ValueKey('shell-narrow'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        AppleIconButton(
                          key: const ValueKey('drawer-toggle'),
                          icon: CupertinoIcons.line_horizontal_3,
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                        const SizedBox(width: 8),
                        const BrandMark(),
                        const SizedBox(width: 10),
                        Text('MindFlow',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: t.label)),
                        const Spacer(),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: state.busy ? t.orange : t.green,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(state.busy ? 'Working…' : 'Ready',
                            style:
                                TextStyle(fontSize: 12, color: t.secondary)),
                      ],
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
    );

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              scaffold,
              const CommandPaletteOverlay(),
              const QuickCaptureOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagePane extends StatefulWidget {
  final FocusNode focusNode;
  const _PagePane({super.key, required this.focusNode});

  @override
  State<_PagePane> createState() => _PagePaneState();
}

class _PagePaneState extends State<_PagePane> {
  static const _iconChoices = ['📄', '📚', '✏️', '🎯', '🧠', '⭐', '🔬', '📝'];

  Future<void> _pickIcon(MindNode node) async {
    final state = context.read<AppState>();
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Page icon'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final icon in _iconChoices)
                InkWell(
                  key: ValueKey('icon-choice-$icon'),
                  onTap: () => Navigator.pop(ctx, icon),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(icon, style: const TextStyle(fontSize: 28)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
    if (chosen == null) return;
    node.icon = chosen.isEmpty ? null : chosen;
    await state.saveNode(node);
  }

  Future<void> _setCover(MindNode node) async {
    final state = context.read<AppState>();
    final controller = TextEditingController(text: node.cover ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cover URL or color'),
        content: TextField(
          key: const ValueKey('cover-field'),
          controller: controller,
          decoration: const InputDecoration(
            hintText: '#4B2E83 or https://…',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Clear')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result == null) return;
    node.cover = result.isEmpty ? null : result;
    await state.saveNode(node);
  }

  Future<void> _addProperty(MindNode node) async {
    final state = context.read<AppState>();
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                key: const ValueKey('prop-key'),
                controller: keyCtrl,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                key: const ValueKey('prop-val'),
                controller: valCtrl,
                decoration: const InputDecoration(labelText: 'Value')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || keyCtrl.text.trim().isEmpty) return;
    node.properties[keyCtrl.text.trim()] = valCtrl.text.trim();
    await state.saveNode(node);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shell = context.watch<ShellState>();
    final t = tk(context);
    final id = shell.currentPage;
    final node = id == null ? null : state.store.nodes[id];

    if (node == null) {
      return Center(
        child: Text('Select a page', style: TextStyle(color: t.secondary)),
      );
    }

    final cover = node.cover;
    Color? coverColor;
    if (cover != null && cover.startsWith('#') && cover.length >= 7) {
      final hex = cover.replaceFirst('#', '');
      coverColor = Color(int.parse('FF$hex', radix: 16));
    }

    final visibleProps = node.properties.entries
        .where((e) =>
            e.key != 'scheduleId' &&
            e.key != 'notes' &&
            e.key != 'assignments')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cover != null && cover.isNotEmpty)
          Container(
            key: const ValueKey('page-cover'),
            height: 96,
            decoration: BoxDecoration(
              color: coverColor ?? t.accent.withValues(alpha: 0.25),
              image: cover.startsWith('http')
                  ? DecorationImage(
                      image: NetworkImage(cover),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(t.lg, t.md, t.lg, t.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InkWell(
                    key: const ValueKey('page-icon-button'),
                    onTap: () => _pickIcon(node),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: node.icon != null && node.icon!.isNotEmpty
                          ? Text(node.icon!,
                              key: const ValueKey('page-header-icon'),
                              style: const TextStyle(fontSize: 28))
                          : Icon(CupertinoIcons.doc,
                              size: 24, color: t.secondary),
                    ),
                  ),
                  SizedBox(width: t.sm),
                  Expanded(
                    child: Text(
                      node.title.isEmpty ? 'Untitled' : node.title,
                      style: TextStyle(
                        fontSize: t.textTitle,
                        fontWeight: FontWeight.w700,
                        color: t.label,
                      ),
                    ),
                  ),
                  AppleIconButton(
                    key: const ValueKey('set-cover-button'),
                    icon: CupertinoIcons.photo,
                    onPressed: () => _setCover(node),
                  ),
                  AppleIconButton(
                    key: const ValueKey('add-prop-button'),
                    icon: CupertinoIcons.tag,
                    onPressed: () => _addProperty(node),
                  ),
                  AppleIconButton(
                    icon: shell.favorites.contains(node.id)
                        ? CupertinoIcons.star_fill
                        : CupertinoIcons.star,
                    color: shell.favorites.contains(node.id)
                        ? t.yellow
                        : t.secondary,
                    onPressed: () => shell.toggleFavorite(node.id),
                  ),
                ],
              ),
              if (visibleProps.isNotEmpty) ...[
                SizedBox(height: t.sm),
                Wrap(
                  key: const ValueKey('page-properties'),
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final e in visibleProps)
                      Container(
                        key: ValueKey('prop-${e.key}'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.elevated,
                          borderRadius: BorderRadius.circular(t.radiusSm),
                        ),
                        child: Text('${e.key}: ${e.value}',
                            style: TextStyle(
                                fontSize: t.textTiny, color: t.secondary)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLinks = constraints.maxWidth >= 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: PageEditor(
                      key: ValueKey('editor-${node.id}'),
                      node: node,
                      focusNode: widget.focusNode,
                      onOpenPage: shell.openPage,
                    ),
                  ),
                  if (showLinks)
                    PageLinksSidebar(
                      node: node,
                      onConvertMention: (title) async {
                        node.body =
                            convertMentionToWikilink(node.body, title);
                        await state.saveNode(node);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OpenPaletteIntent extends Intent {
  const _OpenPaletteIntent();
}

class _NewPageIntent extends Intent {
  const _NewPageIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}

class _FocusEditorIntent extends Intent {
  const _FocusEditorIntent();
}

class _QuickCaptureIntent extends Intent {
  const _QuickCaptureIntent();
}
