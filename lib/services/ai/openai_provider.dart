// ============================================================
// services/ai/openai_provider.dart — OpenAI実装（将来用）
// ============================================================
// TODO: アプリ利用者が増えたら、geminiからchatgptへの移行を検討

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

class OpenAiProvider implements AiProvider {
  final String apiKey;
  final String model;

  OpenAiProvider({
    required this.apiKey,
    this.model = 'gpt-4o-mini', // 安くて速い。gpt-4o に変更も可
  });

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1200,
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final res = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'max_tokens': maxTokens,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userMessage},
            ],
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('OpenAI API error: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['choices'][0]['message']['content'] as String;
  }
}
