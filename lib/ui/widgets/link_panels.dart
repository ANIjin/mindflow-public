import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/memory/study_tools.dart';
import '../../core/models/links.dart';
import '../../core/models/node.dart';
import '../shell_state.dart';
import '../tokens.dart';

class PageLinksSidebar extends StatelessWidget {
  final MindNode node;
  final ValueChanged<String>? onConvertMention;
  const PageLinksSidebar(
      {super.key, required this.node, this.onConvertMention});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shell = context.watch<ShellState>();
    final t = tk(context);
    final inbound = state.store.linkIndex.in_[node.id] ?? const <String>{};
    final outbound = state.store.linkIndex.out[node.id] ?? const <String>{};
    final titles = state.store.nodes.values
        .where((n) => n.id != node.id && n.title.trim().isNotEmpty)
        .map((n) => n.title)
        .toList();
    final mentions = findUnlinkedMentions(node.body, titles);

    return Container(
      key: const ValueKey('page-links-sidebar'),
      width: 280,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: t.hairline)),
        color: t.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView(
          padding: EdgeInsets.all(t.md),
          children: [
          _section(t, 'Backlinks'),
          if (inbound.isEmpty)
            _empty(t, 'No backlinks yet')
          else
            for (final fromId in inbound)
              _row(
                t,
                title: state.store.nodes[fromId]?.title ?? fromId,
                subtitle: 'opens linking page',
                onOpen: () => shell.openPage(fromId),
                keyName: 'backlink-$fromId',
              ),
          SizedBox(height: t.md),
          _section(t, 'Forward links'),
          if (outbound.isEmpty)
            _empty(t, 'No outgoing links')
          else
            for (final toId in outbound)
              _row(
                t,
                title: state.store.nodes[toId]?.title ?? toId,
                subtitle: 'opens linked page',
                onOpen: () => shell.openPage(toId),
                keyName: 'forward-$toId',
              ),
          SizedBox(height: t.md),
          _section(t, 'Unlinked mentions'),
          if (mentions.isEmpty)
            _empty(t, 'No unlinked mentions')
          else
            for (final m in mentions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(m, style: TextStyle(color: t.label, fontSize: 13)),
                trailing: TextButton(
                  key: ValueKey('convert-mention-$m'),
                  onPressed: () => onConvertMention?.call(m),
                  child: const Text('Link'),
                ),
              ),
          SizedBox(height: t.md),
          _section(t, 'Study coverage'),
          if (node.type == 'assignment')
            Padding(
              key: const ValueKey('coverage-count'),
              padding: EdgeInsets.only(bottom: t.sm),
              child: Text(
                '${assignmentCoverage(node)} note${assignmentCoverage(node) == 1 ? '' : 's'} linked',
                style: TextStyle(color: t.label, fontSize: 13),
              ),
            ),
          for (final noteId in linkedNoteIds(node))
            _row(
              t,
              title: state.store.nodes[noteId]?.title ?? noteId,
              subtitle: 'study note',
              onOpen: () => shell.openPage(noteId),
              keyName: 'coverage-note-$noteId',
            ),
          for (final aId in linkedAssignmentIds(node))
            _row(
              t,
              title: state.store.nodes[aId]?.title ?? aId,
              subtitle: 'linked assignment',
              onOpen: () => shell.openPage(aId),
              keyName: 'coverage-assignment-$aId',
            ),
          if (node.type != 'assignment')
            TextButton(
              key: const ValueKey('link-assignment-button'),
              onPressed: () => _pickAssignment(context, state, node),
              child: const Text('Link to assignment'),
            ),
        ],
        ),
      ),
    );
  }

  Future<void> _pickAssignment(
      BuildContext context, AppState state, MindNode note) async {
    final assignments = state.store.nodes.values
        .where((n) => n.type == 'assignment')
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    if (assignments.isEmpty) return;
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Link assignment'),
        children: [
          for (final a in assignments)
            SimpleDialogOption(
              key: ValueKey('pick-assignment-${a.id}'),
              onPressed: () => Navigator.pop(ctx, a.id),
              child: Text(a.title),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await state.linkNoteAssignment(note.id, chosen);
  }

  Widget _section(Tokens t, String title) => Padding(
        padding: EdgeInsets.only(bottom: t.xs),
        child: Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: t.textTiny,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: t.tertiary)),
      );

  Widget _empty(Tokens t, String text) => Padding(
        padding: EdgeInsets.only(bottom: t.sm),
        child: Text(text, style: TextStyle(color: t.secondary, fontSize: 13)),
      );

  Widget _row(Tokens t,
      {required String title,
      required String subtitle,
      required VoidCallback onOpen,
      required String keyName}) {
    return ListTile(
      key: ValueKey(keyName),
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(CupertinoIcons.link, size: 14, color: t.link),
      title: Text(title, style: TextStyle(color: t.label, fontSize: 13)),
      subtitle:
          Text(subtitle, style: TextStyle(color: t.secondary, fontSize: 11)),
      onTap: onOpen,
    );
  }
}

List<String> findUnlinkedMentions(String body, List<String> titles) {
  final linked =
      extractWikilinks(body).map((l) => normalizeTitle(l.target)).toSet();
  final found = <String>[];
  for (final title in titles) {
    final norm = normalizeTitle(title);
    if (linked.contains(norm)) continue;
    if (title.length < 3) continue;
    final pattern = RegExp(RegExp.escape(title), caseSensitive: false);
    if (pattern.hasMatch(body) && !found.contains(title)) {
      found.add(title);
    }
  }
  return found;
}

String convertMentionToWikilink(String body, String title) {
  final pattern = RegExp(RegExp.escape(title), caseSensitive: false);
  final m = pattern.firstMatch(body);
  if (m == null) return body;
  final before = body.substring(0, m.start);
  if (before.lastIndexOf('[[') > before.lastIndexOf(']]')) return body;
  return '${body.substring(0, m.start)}[[$title]]${body.substring(m.end)}';
}
