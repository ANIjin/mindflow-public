import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../core/models/node.dart';
import '../core/models/view_def.dart';
import 'tokens.dart';
import 'widgets/apple.dart';

Future<void> showNodeEditor(BuildContext context, AppState state,
    [MindNode? existing]) async {
  final isNew = existing == null;
  final n = existing ?? MindNode(id: const Uuid().v4());
  final title = TextEditingController(text: n.title);
  final type = TextEditingController(text: n.type);
  final body = TextEditingController(text: n.body);
  final due = TextEditingController(
      text: n.due != null ? n.due!.toIso8601String() : '');
  final priority = TextEditingController(text: '${n.priority}');
  final tags = TextEditingController(text: n.tags.join(', '));
  await appleDialog(
    context,
    title: isNew ? 'New node' : 'Edit node',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        appleField(title, 'Title'),
        Row(
          children: [
            Expanded(
                child: appleField(
                    type, 'Type (assignment/obligation/goal/...)')),
            const SizedBox(width: 10),
            Expanded(child: appleField(priority, 'Priority 0-3')),
          ],
        ),
        appleField(due, 'Due (ISO, e.g. 2026-10-05T20:00:00)'),
        appleField(tags, 'Tags (comma separated)'),
        appleField(body, 'Body', maxLines: 5),
      ],
    ),
    actions: [
      AppleButton('Cancel',
          tone: AppleTone.gray,
          onPressed: () => Navigator.pop(context)),
      const SizedBox(width: 10),
      AppleButton('Save',
          icon: CupertinoIcons.checkmark,
          onPressed: () {
            n.title = title.text.trim();
            n.type = type.text.trim().isEmpty ? 'task' : type.text.trim();
            n.body = body.text;
            n.due = due.text.trim().isEmpty
                ? null
                : DateTime.tryParse(due.text.trim());
            n.priority = int.tryParse(priority.text) ?? 1;
            n.tags = tags.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            Navigator.pop(context);
            state.saveNode(n);
          }),
    ],
  );
}

Future<void> showViewEditor(BuildContext context, AppState state,
    ViewDef v) async {
  final t = tk(context);
  final name = TextEditingController(text: v.name);
  final layout = TextEditingController(text: v.layout);
  final types = TextEditingController(text: v.types.join(', '));
  final tags = TextEditingController(text: v.tags.join(', '));
  final status = TextEditingController(text: v.status ?? '');
  final dueWithin =
      TextEditingController(text: '${v.dueWithinDays ?? ''}');
  final sort = TextEditingController(text: v.sort);
  final groupBy = TextEditingController(text: v.groupBy);
  final order = TextEditingController(text: '${v.order}');
  bool ascending = v.ascending;
  bool pinned = v.pinned;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setS) => Dialog(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          side: BorderSide(color: t.hairline),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: (460).clamp(0.0, MediaQuery.sizeOf(ctx2).width - 40)
                  .toDouble()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit view "${v.name}"',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: t.label)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: appleField(name, 'Name')),
                    const SizedBox(width: 10),
                    Expanded(child: appleField(layout, 'layout')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: appleField(types, 'types (csv)')),
                    const SizedBox(width: 10),
                    Expanded(child: appleField(tags, 'tags (csv)')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: appleField(status, 'status (blank=any)')),
                    const SizedBox(width: 10),
                    Expanded(child: appleField(dueWithin, 'due within days')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: appleField(sort, 'sort')),
                    const SizedBox(width: 10),
                    Expanded(child: appleField(groupBy, 'group_by')),
                    const SizedBox(width: 10),
                    Expanded(child: appleField(order, 'order')),
                  ],
                ),
                Row(
                  children: [
                    AppleCheckbox(
                        value: ascending,
                        onChanged: (b) =>
                            setS(() => ascending = b ?? true)),
                    const Text('ascending',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    AppleCheckbox(
                        value: pinned,
                        onChanged: (b) => setS(() => pinned = b ?? true)),
                    const Text('pinned',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppleButton('Cancel',
                        tone: AppleTone.gray,
                        onPressed: () => Navigator.pop(ctx)),
                    const SizedBox(width: 10),
                    AppleButton('Save',
                        icon: CupertinoIcons.checkmark,
                        onPressed: () {
                          v.name = name.text.trim();
                          v.layout = layout.text.trim();
                          v.types = _csv(types.text);
                          v.tags = _csv(tags.text);
                          v.status = status.text.trim().isEmpty
                              ? null
                              : status.text.trim();
                          v.dueWithinDays =
                              int.tryParse(dueWithin.text.trim());
                          v.sort = sort.text.trim();
                          v.groupBy = groupBy.text.trim();
                          v.order = int.tryParse(order.text) ?? v.order;
                          v.ascending = ascending;
                          v.pinned = pinned;
                          Navigator.pop(ctx);
                          state.store.saveView(v);
                          state.notify();
                        }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

List<String> _csv(String s) => s
    .split(',')
    .map((t) => t.trim())
    .where((t) => t.isNotEmpty)
    .toList();
