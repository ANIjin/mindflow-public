import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/models/node.dart';
import '../tokens.dart';
import 'apple.dart';

Color priorityColor(Tokens t, int p) {
  switch (p) {
    case 0:
      return t.gray;
    case 2:
      return t.orange;
    case 3:
      return t.red;
    default:
      return t.accent;
  }
}

Color typeColor(Tokens t, String type) {
  switch (type) {
    case 'assignment':
      return t.indigo;
    case 'obligation':
      return t.orange;
    case 'goal':
      return t.green;
    case 'project':
      return t.cyan;
    case 'habit':
      return t.yellow;
    case 'event':
      return t.purple;
    default:
      return t.gray;
  }
}

class NodeCard extends StatefulWidget {
  final MindNode node;
  final bool big;
  const NodeCard({super.key, required this.node, this.big = false});

  @override
  State<NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<NodeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final state = context.read<AppState>();
    final t = tk(context);
    final overdue = n.isOverdue;
    final color = priorityColor(t, n.priority);
    return AnimatedContainer(
      duration: t.fast,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd + 2),
        border: Border.all(color: t.hairline),
        boxShadow: [t.shadowHigh],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 2, right: 8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              AppleCheckbox(
                value: n.status == 'done',
                onChanged: (v) {
                  if (v == true) {
                    state.completeNode(n.id);
                  }
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  n.title,
                  style: TextStyle(
                    fontSize: widget.big ? 20 : 14.5,
                    fontWeight: widget.big ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: widget.big ? -0.3 : -0.1,
                    decoration:
                        n.status == 'done' ? TextDecoration.lineThrough : null,
                    color: n.status == 'done' ? t.tertiary : t.label,
                  ),
                ),
              ),
              AppleIconButton(
                icon: CupertinoIcons.trash,
                color: t.tertiary,
                onPressed: () => state.deleteNode(n.id),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                TagChip(typeColor(t, n.type), n.type),
                if (n.due != null)
                  TagChip(
                    overdue ? t.red : t.accent,
                    'due ${DateFormat('MMM d, h:mm a').format(n.due!)}'
                        '${overdue ? ' (OVERDUE)' : ''}',
                  ),
                TagChip(color, 'P${n.priority}'),
                for (final tag in n.tags) TagChip(t.gray, '#$tag'),
                if (n.reminders.isNotEmpty)
                  TagChip(t.green,
                      '${n.reminders.length} reminder(s)'),
              ],
            ),
          ),
          if (n.body.isNotEmpty && (widget.big || _expanded))
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2),
              child: Text(
                n.body,
                style: TextStyle(
                    color: t.secondary, height: 1.4, fontSize: 13.5),
              ),
            ),
          if (n.body.isNotEmpty && !widget.big)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Collapse' : 'More'),
              ),
            ),
        ],
      ),
    );
  }
}
