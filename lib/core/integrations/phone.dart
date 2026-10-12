import 'package:http/http.dart' as http;

import '../memory/memory_store.dart';

class PhoneNotifier {
  PhoneNotifier._();

  static bool enabled = false;
  static String server = 'https://ntfy.sh';
  static String topic = '';

  static void configure(MemoryStore store) {
    final n = (store.settings['integrations'] as Map?)?['ntfy'] as Map?;
    enabled = n?['enabled'] == true;
    server = '${n?['server'] ?? 'https://ntfy.sh'}';
    topic = '${n?['topic'] ?? ''}';
    if (server.endsWith('/')) server = server.substring(0, server.length - 1);
  }

  static Future<String> send(String title, String body,
      {DateTime? delay, int priority = 4}) async {
    if (!enabled || topic.isEmpty) return 'phone notifications are off';
    final uri = Uri.parse('$server/$topic');
    final headers = <String, String>{
      'Title': title,
      'Priority': '$priority',
      'Tags': 'mindflow',
    };
    if (delay != null) {
      if (!delay.isAfter(DateTime.now())) return 'delay is in the past, skipped';
      headers['Delay'] = delay.toUtc().toIso8601String();
    }
    try {
      final r = await http.post(uri, headers: headers, body: body);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return delay != null
            ? 'phone push scheduled for ${delay.toIso8601String()}'
            : 'phone push sent';
      }
      return 'ntfy error ${r.statusCode}: ${r.body}';
    } catch (e) {
      return 'ntfy failed: $e';
    }
  }
}
