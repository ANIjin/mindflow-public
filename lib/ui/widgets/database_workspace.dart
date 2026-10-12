import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/memory/database_engine.dart';
import '../../core/models/node.dart';
import '../../core/models/view_def.dart';
import '../shell_state.dart';
import '../tokens.dart';

class DatabaseWorkspace extends StatefulWidget {
  const DatabaseWorkspace({super.key});

  @override
  State<DatabaseWorkspace> createState() => _DatabaseWorkspaceState();
}

class _DatabaseWorkspaceState extends State<DatabaseWorkspace> {
  String? _selectedViewId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shell = context.watch<ShellState>();
    final t = tk(context);
    final views = state.store.views.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    if (views.isEmpty) {
      return Center(
          child: Text('No views yet', style: TextStyle(color: t.secondary)));
    }
    final selected = views.firstWhere(
      (v) => v.id == (_selectedViewId ?? views.first.id),
      orElse: () => views.first,
    );
    final result = queryDatabase(state.store.nodes.values, selected);
    final cols = visibleColumns(selected);

    return Column(
      key: const ValueKey('database-workspace'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(t.lg, t.md, t.lg, t.sm),
          child: Row(
            children: [
              Text('Databases',
                  style: TextStyle(
                      fontSize: t.textHead,
                      fontWeight: FontWeight.w700,
                      color: t.label)),
              const Spacer(),
              Text('${result.count} nodes',
                  style: TextStyle(color: t.secondary, fontSize: 13)),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: t.md),
            children: [
              for (final v in views)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child:                 ChoiceChip(
                  key: ValueKey('view-chip-${v.id}'),
                  label: Text(
                      '${v.name} (${queryDatabase(state.store.nodes.values, v).count})'),
                  selected: v.id == selected.id,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _selectedViewId = v.id),
                ),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.md, vertical: t.sm),
          child: Wrap(
            spacing: 8,
            children: [
              for (final layout in const [
                'table',
                'board',
                'gallery',
                'calendar',
                'list'
              ])
                ChoiceChip(
                  key: ValueKey('layout-$layout'),
                  label: Text(layout),
                  selected: selected.layout == layout,
                  showCheckmark: false,
                  onSelected: (_) {
                    selected.layout = layout;
                    setState(() {});
                    unawaited(state.store
                        .saveView(selected)
                        .then((_) => state.notify()));
                  },
                ),
            ],
          ),
        ),
        Expanded(child: _layout(context, state, shell, t, selected, result, cols)),
      ],
    );
  }

  Widget _layout(
    BuildContext context,
    AppState state,
    ShellState shell,
    Tokens t,
    ViewDef view,
    DatabaseResult result,
    List<String> cols,
  ) {
    switch (view.layout) {
      case 'board':
        return _BoardLayout(
            groups: result.groups, onOpen: shell.openPage, onToggle: state.completeNode);
      case 'gallery':
        return _GalleryLayout(nodes: result.nodes, onOpen: shell.openPage);
      case 'calendar':
        return _CalendarLayout(nodes: result.nodes, onOpen: shell.openPage);
      case 'list':
        return _ListLayout(
            nodes: result.nodes,
            cols: cols,
            onOpen: shell.openPage,
            onToggle: state.completeNode,
            onEdit: state.saveNode);
      case 'table':
      default:
        return _TableLayout(
            nodes: result.nodes,
            cols: cols,
            onOpen: shell.openPage,
            onToggle: state.completeNode,
            onEdit: state.saveNode);
    }
  }
}

class _TableLayout extends StatelessWidget {
  final List<MindNode> nodes;
  final List<String> cols;
  final ValueChanged<String> onOpen;
  final Future<void> Function(String) onToggle;
  final Future<void> Function(MindNode) onEdit;
  const _TableLayout(
      {required this.nodes,
      required this.cols,
      required this.onOpen,
      required this.onToggle,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
        return SingleChildScrollView(
          key: const ValueKey('layout-table-view'),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: ListView.builder(
              itemCount: nodes.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Row(
                    children: [
                      for (final c in cols)
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(c.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: t.tertiary)),
                        )),
                    ],
                  );
                }
                final n = nodes[i - 1];
                return InkWell(
                  key: ValueKey('row-${n.id}'),
                  onTap: () => onOpen(n.id),
                  child: Row(
                    children: [
                      for (final c in cols)
                        Expanded(child: _cell(context, n, c)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _cell(BuildContext context, MindNode n, String col) {
    final t = tk(context);
    if (col == 'status') {
      return Checkbox(
        key: ValueKey('status-${n.id}'),
        value: n.status == 'done',
        onChanged: (_) => onToggle(n.id),
      );
    }
    if (col == 'title') {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(n.title.isEmpty ? 'Untitled' : n.title,
            style: TextStyle(color: t.label)),
      );
    }
    if (col == 'priority') {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text('${n.priority}', style: TextStyle(color: t.secondary)),
      );
    }
    if (col == 'due') {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(n.due?.toIso8601String().split('T').first ?? '—',
            style: TextStyle(color: t.secondary)),
      );
    }
    if (col == 'tags') {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(n.tags.join(', '), style: TextStyle(color: t.secondary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text('${n.properties[col] ?? ''}',
          style: TextStyle(color: t.secondary)),
    );
  }
}

class _BoardLayout extends StatelessWidget {
  final Map<String, List<MindNode>> groups;
  final ValueChanged<String> onOpen;
  final Future<void> Function(String) onToggle;
  const _BoardLayout(
      {required this.groups, required this.onOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return ListView(
      key: const ValueKey('layout-board-view'),
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(t.md),
      children: [
        for (final e in groups.entries)
          Container(
            width: 260,
            margin: EdgeInsets.only(right: t.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${e.key} (${e.value.length})',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: t.label)),
                SizedBox(height: t.sm),
                Expanded(
                  child: ListView(
                    children: [
                      for (final n in e.value)
                        Card(
                          key: ValueKey('card-${n.id}'),
                          child: ListTile(
                            title: Text(n.title),
                            trailing: Checkbox(
                              value: n.status == 'done',
                              onChanged: (_) => onToggle(n.id),
                            ),
                            onTap: () => onOpen(n.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GalleryLayout extends StatelessWidget {
  final List<MindNode> nodes;
  final ValueChanged<String> onOpen;
  const _GalleryLayout({required this.nodes, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return GridView.builder(
      key: const ValueKey('layout-gallery-view'),
      padding: EdgeInsets.all(t.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: nodes.length,
      itemBuilder: (context, i) {
        final n = nodes[i];
        return InkWell(
          key: ValueKey('gallery-${n.id}'),
          onTap: () => onOpen(n.id),
          child: Container(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(t.radiusMd),
              border: Border.all(color: t.hairline),
            ),
            padding: EdgeInsets.all(t.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.icon ?? '📄', style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Text(n.title.isEmpty ? 'Untitled' : n.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: t.label)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalendarLayout extends StatelessWidget {
  final List<MindNode> nodes;
  final ValueChanged<String> onOpen;
  const _CalendarLayout({required this.nodes, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final withDue = nodes.where((n) => n.due != null).toList()
      ..sort((a, b) => a.due!.compareTo(b.due!));
    return ListView(
      key: const ValueKey('layout-calendar-view'),
      padding: EdgeInsets.all(t.md),
      children: [
        for (final n in withDue)
          ListTile(
            key: ValueKey('cal-${n.id}'),
            leading: Icon(CupertinoIcons.calendar, color: t.accent),
            title: Text(n.title),
            subtitle: Text(n.due!.toIso8601String().split('T').first),
            onTap: () => onOpen(n.id),
          ),
      ],
    );
  }
}

class _ListLayout extends StatelessWidget {
  final List<MindNode> nodes;
  final List<String> cols;
  final ValueChanged<String> onOpen;
  final Future<void> Function(String) onToggle;
  final Future<void> Function(MindNode) onEdit;
  const _ListLayout(
      {required this.nodes,
      required this.cols,
      required this.onOpen,
      required this.onToggle,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return ListView.separated(
      key: const ValueKey('layout-list-view'),
      padding: EdgeInsets.all(t.md),
      itemCount: nodes.length,
      separatorBuilder: (_, __) => Divider(color: t.hairline),
      itemBuilder: (context, i) {
        final n = nodes[i];
        return ListTile(
          key: ValueKey('list-${n.id}'),
          leading: Checkbox(
            key: ValueKey('list-status-${n.id}'),
            value: n.status == 'done',
            onChanged: (_) => onToggle(n.id),
          ),
          title: Text(n.title.isEmpty ? 'Untitled' : n.title),
          subtitle: Text([
            if (cols.contains('status')) n.status,
            if (cols.contains('priority')) 'p${n.priority}',
            if (cols.contains('due') && n.due != null)
              n.due!.toIso8601String().split('T').first,
          ].join(' · ')),
          onTap: () => onOpen(n.id),
        );
      },
    );
  }
}
