import 'dart:convert';

import 'ai_client.dart';
import 'tools.dart';

class ChatMsg {
  final String role;
  final String content;
  final DateTime ts;
  final List<String> activity;
  ChatMsg(this.role, this.content, this.ts, [List<String>? activity])
      : activity = activity ?? [];
}

class AgentResult {
  final String reply;
  final List<String> activities;
  AgentResult(this.reply, this.activities);
}

const _systemPrompt = '''
You are the MindFlow agent, an autonomous personal organizer living in the user's
memory directory. You manage MindNodes (typed blocks: assignment, obligation, goal,
task, project, note, habit, event, page, capture - you may invent new types) and
Views (database layouts over nodes: table, board, gallery, calendar, list). You
have tools to create/update/delete nodes, schedule push reminders, create/update/
delete views, read/write long-term memory, and read the event log.

Knowledge-base tools:
- create_page / update_page_body / append_block for markdown pages (nested via parent_id)
- link_pages to connect pages (wikilinks + links field stay in sync)
- search for full-text vault search
- create_database_view for filtered/sorted database views
- add_review_card / grade_card for spaced-repetition review
- plan_exams to generate study-plan pages before an exam date

Principles:
- Capture everything the user shares into nodes with sensible type, tags, priority,
  due date, and reminders (e.g. 24h before a deadline, a morning-of reminder, and
  one at 2h before for urgent items).
- Keep the board adaptive: maintain views that surface what matters right now
  (deadlines this week, blocked items, goals in progress). Delete stale views,
  reorder so the most relevant view is first.
- Prefer pages + wikilinks for lasting notes; use databases for collections.
- Record durable facts, decisions and context in memory.md as short dated entries.
- Use get_summary, list_nodes, and search before acting so you know current state.
- External sources: sync_integrations pulls Blackboard, Aktiv
  and Outlook (school mail/calendar) into nodes tagged by source. list_schedule,
  add_class, remove_class and import_ics manage the user's weekly class schedule
  shown on the Calendar tab. Sync schedule conflicts into reminders (e.g. a
  deadline during class time means the work must be done earlier).
- notify_phone sends a push to the user's phone via ntfy (immediate, or delayed
  to an ISO datetime). Use it for urgent alerts and messages the user asks to
  receive on their phone.
- When the user is vague, ask one clarifying question; otherwise act.
- Reply in concise markdown. After acting, summarize what you changed.
- All datetimes you pass are ISO-8601 local time (e.g. 2026-10-05T20:00:00).
- The "Current local datetime" line below is authoritative for today/tomorrow and
  relative dates. Do not guess the date; use that value.
''';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// System prompt with the live local clock injected (testable).
String buildSystemPrompt([DateTime? now]) {
  final at = now ?? DateTime.now();
  final weekday = _weekdays[at.weekday - 1];
  final y = at.year.toString().padLeft(4, '0');
  final m = at.month.toString().padLeft(2, '0');
  final d = at.day.toString().padLeft(2, '0');
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  final ss = at.second.toString().padLeft(2, '0');
  final offset = at.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final oh = offset.inHours.abs().toString().padLeft(2, '0');
  final om = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '$_systemPrompt\n'
      'Current local datetime: $y-$m-$d'
      'T$hh:$mm:$ss$sign$oh:$om ($weekday).\n'
      'Today\'s calendar date is $y-$m-$d.';
}

class Agent {
  final AiClient client;
  final ToolExecutor exec;

  Agent(this.client, this.exec);

  Future<AgentResult> run(String userMessage, List<ChatMsg> history) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': buildSystemPrompt()},
    ];
    final recent = history.where((m) => m.role == 'user' || m.role == 'assistant').toList();
    final slice = recent.length > 16 ? recent.sublist(recent.length - 16) : recent;
    for (final m in slice) {
      messages.add({'role': m.role, 'content': m.content});
    }
    messages.add({'role': 'user', 'content': userMessage});

    for (int round = 0; round < 8; round++) {
      final reply = await client.chat(messages, tools: toolSchemas);
      if (reply.toolCalls.isEmpty) {
        return AgentResult(reply.content ?? '(no reply)', exec.activities);
      }
      messages.add({
        'role': 'assistant',
        'content': reply.content ?? '',
        'tool_calls': reply.toolCalls
            .map((c) => {
                  'id': c.id,
                  'type': 'function',
                  'function': {'name': c.name, 'arguments': jsonEncode(c.args)},
                })
            .toList(),
      });
      for (final c in reply.toolCalls) {
        final result = await exec.execute(c.name, c.args);
        messages.add({
          'role': 'tool',
          'tool_call_id': c.id,
          'content': result,
        });
      }
    }
    return AgentResult('(stopped after 8 tool rounds)', exec.activities);
  }
}
