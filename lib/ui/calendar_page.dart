import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../core/models/node.dart';
import 'node_editor.dart';
import 'tokens.dart';
import 'widgets/apple.dart';
import 'widgets/node_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late AppState state;
  DateTime focus = DateTime.now();
  String mode = 'month';

  @override
  void initState() {
    super.initState();
    state = context.read<AppState>();
  }

  DateTime get _today => DateTime.now();

  DateTime get _weekStart {
    final d = DateTime(focus.year, focus.month, focus.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<MindNode> _nodesOn(DateTime day) {
    return state.store.nodes.values.where((n) {
      if (n.due != null && _isSameDay(n.due!, day)) return true;
      return n.reminders.any((r) => _isSameDay(r, day));
    }).toList()
      ..sort((a, b) {
        final ad = a.due, bd = b.due;
        if (ad != null && bd != null) return ad.compareTo(bd);
        if (ad != null) return -1;
        if (bd != null) return 1;
        return 0;
      });
  }

  List<MindNode> _eventsOn(DateTime day) {
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    return state.store.nodes.values.where((n) {
      if (n.type != 'event') return false;
      final s = DateTime.tryParse(n.meta['start'] as String? ?? '');
      return s != null && isSameDay(s, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Column(
      children: [
        PageHeader('Calendar',
            subtitle: _title(),
            trailing: [
              AppleSegmented(
                options: const ['Day', 'Week', 'Month', 'Year'],
                selected: mode[0].toUpperCase() + mode.substring(1),
                onChanged: (s) =>
                    setState(() => mode = s.toLowerCase()),
              ),
              const SizedBox(width: 14),
              AppleIconButton(
                  icon: CupertinoIcons.chevron_left,
                  color: t.label,
                  onPressed: () => setState(() => focus = _shift(-1))),
              AppleButton('Today',
                  tone: AppleTone.gray,
                  onPressed: () => setState(() => focus = _today)),
              AppleIconButton(
                  icon: CupertinoIcons.chevron_right,
                  color: t.label,
                  onPressed: () => setState(() => focus = _shift(1))),
            ]),
        Expanded(
          child: switch (mode) {
            'day' => _dayView(t),
            'week' => _weekView(t),
            'year' => _yearView(t),
            _ => _monthView(t),
          },
        ),
      ],
    );
  }

  DateTime _shift(int dir) {
    switch (mode) {
      case 'day':
        return focus.add(Duration(days: dir));
      case 'week':
        return focus.add(Duration(days: 7 * dir));
      case 'year':
        return DateTime(focus.year + dir, focus.month, 1);
      default:
        return DateTime(focus.year, focus.month + dir, 1);
    }
  }

  String _title() {
    switch (mode) {
      case 'day':
        return DateFormat('EEEE, MMMM d, yyyy').format(focus);
      case 'week':
        final ws = _weekStart;
        final we = ws.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(ws)} - ${DateFormat('MMM d, yyyy').format(we)}';
      case 'year':
        return '${focus.year}';
      default:
        return DateFormat('MMMM yyyy').format(focus);
    }
  }

  Widget _monthView(Tokens t) {
    final first = DateTime(focus.year, focus.month, 1);
    final daysInMonth = DateTime(focus.year, focus.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = <DateTime>[];
    for (int i = 0; i < leading; i++) {
      cells.add(first.subtract(Duration(days: leading - i)));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(focus.year, focus.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(cells.last.add(const Duration(days: 1)));
    }
    final rows = (cells.length / 7).ceil();
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              for (final l in labels)
                Expanded(
                  child: Text(l,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: t.secondary)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (int r = 0; r < rows; r++)
            Column(
              children: [
                SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      for (int c = 0; c < 7; c++)
                        Expanded(child: _monthCell(t, cells[r * 7 + c])),
                    ],
                  ),
                ),
                const Hairline(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _monthCell(Tokens t, DateTime day) {
    final isToday = _isSameDay(day, _today);
    final inMonth = day.month == focus.month;
    final nodes = _nodesOn(day);
    final classes = state.schedule.onDay(day);
    return InkWell(
      onTap: () => setState(() {
        focus = day;
        mode = 'day';
      }),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: inMonth ? t.card : t.elevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          color: t.red, shape: BoxShape.circle)
                      : null,
                  child: Text('${day.day}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? Colors.white
                              : (inMonth ? t.label : t.tertiary))),
                ),
              ],
            ),
            const SizedBox(height: 2),
            for (final c in classes.take(2))
              Text(
                '${c.startLabel} ${c.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9, color: t.purple),
              ),
            for (final n in nodes.where((n) => n.due != null).take(2))
              Text(
                n.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9,
                    color: n.isOverdue ? t.red : t.accent),
              ),
            const Spacer(),
            Row(
              children: [
                for (final n in nodes.take(5))
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                        color: priorityColor(t, n.priority),
                        shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekView(Tokens t) {
    const startHour = 7, endHour = 21, hourH = 40.0;
    final ws = _weekStart;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      focus = ws.add(Duration(days: i));
                      mode = 'day';
                    }),
                    child: Column(
                      children: [
                        Text(labels7[i],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: t.secondary)),
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration:
                              _isSameDay(ws.add(Duration(days: i)), _today)
                                  ? BoxDecoration(
                                      color: t.red,
                                      shape: BoxShape.circle)
                                  : null,
                          child: Text('${ws.add(Duration(days: i)).day}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _isSameDay(
                                          ws.add(Duration(days: i)), _today)
                                      ? Colors.white
                                      : t.label)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final n in _nodesOn(ws.add(Duration(days: i)))
                                .take(4))
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 1),
                                decoration: BoxDecoration(
                                    color: priorityColor(t, n.priority),
                                    shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: (endHour - startHour) * hourH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      for (int h = startHour; h < endHour; h++)
                        SizedBox(
                          height: hourH,
                          child: Text('$h:00',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: t.tertiary)),
                        ),
                    ],
                  ),
                ),
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: _weekColumn(t, ws.add(Duration(days: i)),
                        startHour, endHour, hourH),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekColumn(Tokens t, DateTime day, int startHour, int endHour,
      double hourH) {
    final blocks = <Widget>[];
    for (int h = startHour; h < endHour; h++) {
      blocks.add(Positioned(
        top: (h - startHour) * hourH,
        left: 0,
        right: 0,
        child: Container(height: 1, color: t.hairline),
      ));
    }
    final items = <_TimeBlock>[];
    for (final c in state.schedule.onDay(day)) {
      items.add(_TimeBlock(c.startMin, c.endMin, c.name, t.purple));
    }
    for (final n in _eventsOn(day)) {
      final s = DateTime.parse(n.meta['start'] as String);
      final e = DateTime.tryParse(n.meta['end'] as String? ?? '') ??
          s.add(const Duration(hours: 1));
      items.add(_TimeBlock(
          s.hour * 60 + s.minute, e.hour * 60 + e.minute, n.title,
          t.accent));
    }
    for (final b in items) {
      final top = (b.start - startHour * 60) / 60.0 * hourH;
      final height = (b.end - b.start) / 60.0 * hourH;
      if (top + height < 0) continue;
      blocks.add(Positioned(
        top: top.clamp(0, (endHour - startHour) * hourH),
        left: 2,
        right: 2,
        height: height.clamp(16, (endHour - startHour) * hourH),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: b.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: b.color.withValues(alpha: 0.45)),
          ),
          child: Text(
            '${b.startLabel} ${b.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: b.color),
          ),
        ),
      ));
    }
    final remItems = <List<dynamic>>[];
    for (final n in _nodesOn(day)) {
      for (final r in n.reminders) {
        if (!_isSameDay(r, day)) continue;
        final top = (r.hour * 60 + r.minute - startHour * 60) / 60.0 * hourH;
        if (top < 0 || top > (endHour - startHour) * hourH) continue;
        remItems.add([top, r, n.title]);
      }
    }
    remItems.sort((a, b) => (a[0] as double).compareTo(b[0] as double));
    double prevBottom = -100;
    for (final e in remItems) {
      final r = e[1] as DateTime;
      final title = e[2] as String;
      final top = (e[0] as double) > prevBottom + 13
          ? e[0] as double
          : prevBottom + 13;
      prevBottom = top;
      blocks.add(Positioned(
        top: top,
        left: 2,
        right: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: t.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: t.green.withValues(alpha: 0.4)),
          ),
          child: Text(
            '\u{1F514} ${r.hour.toString().padLeft(2, '0')}:'
                '${r.minute.toString().padLeft(2, '0')} $title',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 8, color: t.green),
          ),
        ),
      ));
    }
    return Stack(children: blocks);
  }

  Widget _dayView(Tokens t) {
    final nodes = _nodesOn(focus);
    final classes = state.schedule.onDay(focus);
    final events = _eventsOn(focus);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        if (classes.isNotEmpty || events.isNotEmpty)
          SectionCard(
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SCHEDULE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: t.secondary)),
                const SizedBox(height: 6),
                for (final c in classes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${c.startLabel}\n${c.endLabel}',
                            style: TextStyle(
                                fontSize: 11, color: t.secondary),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: t.purple)),
                              if (c.location.isNotEmpty)
                                Text(c.location,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: t.secondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final e in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => showNodeEditor(context, state, e),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            child: Text(
                              DateFormat('h:mm a').format(
                                  DateTime.parse(e.meta['start'] as String)),
                              style: TextStyle(
                                  fontSize: 11, color: t.secondary),
                            ),
                          ),
                          Expanded(
                            child: Text(e.title,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: t.accent)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Text('DUE / REMINDERS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: t.secondary)),
        const SizedBox(height: 6),
        if (nodes.isEmpty)
          Text('nothing scheduled this day',
              style: TextStyle(color: t.tertiary, fontSize: 12))
        else
          for (final n in nodes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NodeCard(node: n),
                  if (n.reminders.any((r) => _isSameDay(r, focus)))
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 3),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final r
                              in n.reminders.where((r) => _isSameDay(r, focus)))
                            Text(
                              '\u{1F514} ${DateFormat('h:mm a').format(r)}',
                              style: TextStyle(
                                  fontSize: 10, color: t.green),
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

  Widget _yearView(Tokens t) {
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      crossAxisCount: 4,
      childAspectRatio: 0.72,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (int m = 1; m <= 12; m++)
          InkWell(
            onTap: () => setState(() {
              focus = DateTime(focus.year, m, 1);
              mode = 'month';
            }),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: m == focus.month ? t.accent : t.hairline),
                boxShadow: [t.shadowHigh],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMMM').format(DateTime(focus.year, m)),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: t.label)),
                  const SizedBox(height: 2),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, cons) {
                        final first = DateTime(focus.year, m, 1);
                        final dim = DateTime(focus.year, m + 1, 0).day;
                        final leading = first.weekday - 1;
                        final rows = ((leading + dim) / 7).ceil();
                        final cols = cons.maxWidth / 7;
                        final cellH = cons.maxHeight / rows;
                        final byDay = <int, List<MindNode>>{};
                        for (final n in state.store.nodes.values) {
                          if (n.due != null &&
                              n.due!.year == focus.year &&
                              n.due!.month == m) {
                            byDay.putIfAbsent(n.due!.day, () => []).add(n);
                          }
                        }
                        return Column(
                          children: [
                            for (int r = 0; r < rows; r++)
                              SizedBox(
                                height: cellH,
                                child: Row(
                                  children: [
                                    for (int c = 0; c < 7; c++)
                                      SizedBox(
                                        width: cols,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _miniDayLabel(r * 7 + c,
                                                    leading, dim, m),
                                                style: TextStyle(
                                                    fontSize: 8,
                                                    color: t.secondary),
                                              ),
                                              Container(
                                                width: 3,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: byDay[r * 7 + c -
                                                              leading + 1] !=
                                                          null
                                                      ? priorityColor(t,
                                                          byDay[r * 7 + c -
                                                                  leading +
                                                                  1]!
                                                              .first
                                                              .priority)
                                                      : Colors.transparent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _miniDayLabel(int idx, int leading, int dim, int month) {
    final d = idx - leading + 1;
    if (d < 1 || d > dim) return '';
    return '$d';
  }

  static const labels7 = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

class _TimeBlock {
  final int start;
  final int end;
  final String title;
  final Color color;
  _TimeBlock(this.start, this.end, this.title, this.color);

  String get startLabel {
    final h = start ~/ 60, m = start % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
