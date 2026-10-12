import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/memory/memory_store.dart';
import '../../core/models/node.dart';
import '../shell_state.dart';
import '../tokens.dart';

class SidebarNav extends StatelessWidget {
  final MemoryStore store;

  const SidebarNav({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellState>();
    final t = tk(context);

    final byParent = <String, List<MindNode>>{};
    final roots = <String, List<MindNode>>{};
    for (final n in store.nodes.values) {
      if (n.parentId == null) {
        roots.putIfAbsent(n.spaceId ?? 'MindFlow', () => []).add(n);
      } else {
        byParent.putIfAbsent(n.parentId!, () => []).add(n);
      }
    }
    for (final l in roots.values) {
      l.sort((a, b) => a.title.compareTo(b.title));
    }
    for (final l in byParent.values) {
      l.sort((a, b) => a.title.compareTo(b.title));
    }

    final spaceNames = roots.keys.toList()..sort();
    final favNodes = <MindNode>[];
    for (final id in shell.favorites) {
      final n = store.nodes[id];
      if (n != null) favNodes.add(n);
    }
    favNodes.sort((a, b) => a.title.compareTo(b.title));
    final recentNodes = <MindNode>[];
    for (final id in shell.recents) {
      final n = store.nodes[id];
      if (n != null) recentNodes.add(n);
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: t.sm + 2),
      children: [
        for (final space in spaceNames) ...[
          _header(context, t, 'Space: $space'),
          for (final root in roots[space]!)
            _node(context, shell, t, root, byParent, 0),
          SizedBox(height: t.sm),
        ],
        if (favNodes.isNotEmpty) ...[
          _header(context, t, 'Favorites'),
          for (final n in favNodes) _node(context, shell, t, n, byParent, 0),
          SizedBox(height: t.sm),
        ],
        if (recentNodes.isNotEmpty) ...[
          _header(context, t, 'Recents'),
          for (final n in recentNodes) _node(context, shell, t, n, byParent, 0),
          SizedBox(height: t.sm),
        ],
      ],
    );
  }

  Widget _header(BuildContext context, Tokens t, String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(t.sm + 2, t.sm, t.sm + 2, t.xs / 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: t.textTiny,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: t.tertiary,
        ),
      ),
    );
  }

  Widget _node(BuildContext context, ShellState shell, Tokens t, MindNode n,
      Map<String, List<MindNode>> byParent, int depth) {
    final children = byParent[n.id] ?? const [];
    final hasChildren = children.isNotEmpty;
    final isExpanded = shell.expanded.contains(n.id);
    final selected = shell.currentPage == n.id;
    final collapsed = shell.sidebarCollapsed;

    final row = Padding(
      key: ValueKey('page-${n.id}'),
      padding: EdgeInsets.only(left: collapsed ? 0 : depth * 14.0),
      child: InkWell(
        onTap: () => shell.openPage(n.id),
        hoverColor: t.label.withValues(alpha: 0.04),
        focusColor: t.focusRing.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(t.radiusSm + 2),
        child: AnimatedContainer(
          duration: t.fast,
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: t.sm),
          decoration: BoxDecoration(
            color: selected ? t.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(t.radiusSm + 2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: t.accent.withValues(alpha: 0.13),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (hasChildren && !collapsed)
                SizedBox(
                  width: 20,
                  child: InkWell(
                    key: ValueKey('expand-${n.id}'),
                    onTap: () => shell.toggleExpanded(n.id),
                    child: Icon(
                      isExpanded
                          ? CupertinoIcons.chevron_down
                          : CupertinoIcons.chevron_right,
                      size: 11,
                      color: t.secondary,
                    ),
                  ),
                )
              else if (!collapsed)
                const SizedBox(width: 20),
              if (n.icon != null && n.icon!.isNotEmpty)
                Text(n.icon!, style: TextStyle(fontSize: 13))
              else
                Icon(CupertinoIcons.doc, size: 14,
                    color: selected ? Colors.white : t.secondary),
              if (!collapsed) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    n.title.isEmpty ? 'Untitled' : n.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : t.label,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (hasChildren && isExpanded && !collapsed) {
      return Column(
        children: [row, for (final c in children) _node(context, shell, t, c, byParent, depth + 1)],
      );
    }
    return row;
  }
}
