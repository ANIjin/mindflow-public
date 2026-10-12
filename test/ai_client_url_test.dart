import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/ai/ai_client.dart';

void main() {
  test('normalizeBaseUrl appends /v1 for bare LM Studio roots', () {
    expect(AiClient.normalizeBaseUrl('http://127.0.0.1:1234'),
        'http://127.0.0.1:1234/v1');
    expect(AiClient.normalizeBaseUrl('http://127.0.0.1:1234/'),
        'http://127.0.0.1:1234/v1');
    expect(AiClient.normalizeBaseUrl('http://127.0.0.1:1234/v1'),
        'http://127.0.0.1:1234/v1');
    expect(AiClient.normalizeBaseUrl('http://127.0.0.1:1234/v1/'),
        'http://127.0.0.1:1234/v1');
  });
}
