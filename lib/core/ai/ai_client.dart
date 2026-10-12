import 'dart:convert';

import 'package:http/http.dart' as http;

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> args;
  ToolCall(this.id, this.name, this.args);
}

class AiReply {
  final String? content;
  final List<ToolCall> toolCalls;
  AiReply({this.content, List<ToolCall>? toolCalls})
      : toolCalls = toolCalls ?? [];
}

class AiClient {
  String baseUrl;
  String model;
  String apiKey;

  AiClient({required this.baseUrl, required this.model, this.apiKey = ''});

  /// Normalize OpenAI-compatible roots (LM Studio / Ollama style).
  ///
  /// Accepts `http://host:1234`, `http://host:1234/`, or
  /// `http://host:1234/v1` and always returns a root that ends with `/v1`
  /// (no trailing slash).
  static String normalizeBaseUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return u;
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.endsWith('/v1')) return u;
    // Common LM Studio mistake: port root without /v1.
    return '$u/v1';
  }

  String get _root => normalizeBaseUrl(baseUrl);

  Future<AiReply> chat(
    List<Map<String, dynamic>> messages, {
    List<Map<String, dynamic>>? tools,
    double temperature = 0.4,
    int maxTokens = 2048,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };
    if (tools != null && tools.isNotEmpty) body['tools'] = tools;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Many local servers accept any/no key; send a placeholder if blank.
      'Authorization': 'Bearer ${apiKey.isEmpty ? 'lm-studio' : apiKey}',
    };
    final url = '$_root/chat/completions';
    final res = await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 180));
    if (res.statusCode != 200) {
      throw Exception(
          'AI endpoint error ${res.statusCode} ($url): ${_clip(res.body)}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw Exception(
          'AI endpoint returned non-JSON object from $url: ${_clip(res.body)}');
    }
    final j = Map<String, dynamic>.from(decoded);

    if (j['error'] != null) {
      final err = j['error'];
      final msg = err is Map
          ? (err['message'] ?? err.toString())
          : err.toString();
      throw Exception('AI endpoint error: $msg');
    }

    final choicesRaw = j['choices'];
    if (choicesRaw is! List || choicesRaw.isEmpty) {
      throw Exception(
          'AI endpoint response missing choices from $url. '
          'Check Base URL ends with /v1 (LM Studio: http://127.0.0.1:1234/v1) '
          'and the model id matches the loaded model. Body: ${_clip(res.body)}');
    }
    final choice = choicesRaw.first;
    if (choice is! Map) {
      throw Exception('AI endpoint returned a malformed choice: $choice');
    }
    final msgRaw = choice['message'] ?? choice['delta'];
    if (msgRaw is! Map) {
      // Some servers return text completion style.
      final text = choice['text'];
      if (text is String) return AiReply(content: text);
      throw Exception(
          'AI endpoint choice missing message: ${_clip(jsonEncode(choice))}');
    }
    final msg = Map<String, dynamic>.from(msgRaw);

    final content = msg['content'];
    String? contentText;
    if (content is String) {
      contentText = content;
    } else if (content is List) {
      // OpenAI multimodal / some local servers return content parts.
      contentText = content
          .map((p) {
            if (p is Map && p['type'] == 'text') return '${p['text'] ?? ''}';
            if (p is String) return p;
            return '';
          })
          .where((s) => s.isNotEmpty)
          .join('\n');
    }

    final calls = <ToolCall>[];
    final toolCalls = msg['tool_calls'];
    if (toolCalls is List) {
      for (final tc in toolCalls) {
        if (tc is! Map) continue;
        final fn = tc['function'];
        if (fn is! Map) continue;
        calls.add(ToolCall(
          tc['id'] as String? ?? '',
          fn['name'] as String? ?? '',
          _parseArgs(fn['arguments']),
        ));
      }
    }

    return AiReply(content: contentText, toolCalls: calls);
  }

  static String _clip(String s, [int n = 400]) {
    final t = s.trim();
    if (t.length <= n) return t;
    return '${t.substring(0, n)}…';
  }

  static Map<String, dynamic> _parseArgs(dynamic a) {
    if (a is Map) return a.cast<String, dynamic>();
    if (a is String) {
      try {
        return (jsonDecode(a) as Map).cast<String, dynamic>();
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}
