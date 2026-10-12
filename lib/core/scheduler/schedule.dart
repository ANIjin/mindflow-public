import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ClassSlot {
  String id;
  String name;
  int weekday;
  int startMin;
  int endMin;
  String location;

  ClassSlot({
    required this.id,
    this.name = '',
    this.weekday = 1,
    this.startMin = 540,
    this.endMin = 600,
    this.location = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weekday': weekday,
        'start': startMin,
        'end': endMin,
        'location': location,
      };

  factory ClassSlot.fromJson(Map<String, dynamic> j) => ClassSlot(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        weekday: j['weekday'] as int? ?? 1,
        startMin: j['start'] as int? ?? 540,
        endMin: j['end'] as int? ?? 600,
        location: j['location'] as String? ?? '',
      );

  String get startLabel {
    final h = startMin ~/ 60, m = startMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String get endLabel {
    final h = endMin ~/ 60, m = endMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String toSummary() =>
      '[$id] "$name" day=$weekday $startLabel-$endLabel location=$location';
}

class ScheduleStore {
  final String root;
  final List<ClassSlot> slots = [];

  ScheduleStore(this.root);

  String get _file => p.join(root, 'schedule.json');

  static Future<ScheduleStore> open(String root) async {
    final s = ScheduleStore(root);
    final f = File(p.join(root, 'schedule.json'));
    if (f.existsSync()) {
      try {
        final list = jsonDecode(f.readAsStringSync()) as List;
        for (final e in list) {
          s.slots.add(ClassSlot.fromJson((e as Map).cast<String, dynamic>()));
        }
      } catch (_) {}
    }
    return s;
  }

  Future<void> save() async {
    await File(_file)
        .writeAsString(jsonEncode(slots.map((s) => s.toJson()).toList()));
  }

  Future<void> addSlot(ClassSlot s) async {
    slots.add(s);
    await save();
  }

  Future<void> removeSlot(String id) async {
    slots.removeWhere((s) => s.id == id);
    await save();
  }

  List<ClassSlot> onDay(DateTime day) =>
      slots.where((s) => s.weekday == day.weekday).toList()
        ..sort((a, b) => a.startMin.compareTo(b.startMin));

  Future<int> importIcs(String text) async {
    int added = 0;
    const dayMap = {'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7};
    for (final block in text.split('BEGIN:VEVENT')) {
      if (!block.contains('END:VEVENT')) continue;
      final body = block.split('END:VEVENT').first;
      String name = '';
      int startMin = 540;
      int endMin = 600;
      final days = <int>[];
      for (final raw in body.split(RegExp(r'\r?\n'))) {
        final line = raw.trim();
        if (line.startsWith('SUMMARY:')) {
          name = line.substring(8).trim();
        } else if (line.startsWith('DTSTART')) {
          final v = line.split(':').last.trim();
          if (v.length >= 9) {
            startMin = int.parse(v.substring(9, 11)) * 60 + int.parse(v.substring(11, 13));
            days.add(DateTime(int.parse(v.substring(0, 4)), int.parse(v.substring(4, 6)), int.parse(v.substring(6, 8))).weekday);
          }
        } else if (line.startsWith('DURATION:PT')) {
          final m = RegExp(r'(\d+)M').firstMatch(line.substring(10));
          if (m != null) endMin = startMin + int.parse(m.group(1)!);
        } else if (line.startsWith('RRULE:')) {
          final r = line.substring(6);
          if (r.contains('FREQ=WEEKLY')) {
            final by = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(r);
            if (by != null) {
              days.clear();
              for (final d in by.group(1)!.split(',')) {
                if (dayMap[d] != null) days.add(dayMap[d]!);
              }
            }
          }
        }
      }
      if (name.isEmpty || days.isEmpty) continue;
      for (final d in days) {
        slots.add(ClassSlot(
            id: const Uuid().v4(),
            name: name,
            weekday: d,
            startMin: startMin,
            endMin: endMin));
        added++;
      }
    }
    if (added > 0) await save();
    return added;
  }
}
