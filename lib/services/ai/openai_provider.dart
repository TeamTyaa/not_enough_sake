// ============================================================
// OpenAIプロバイダ
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
  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userMessage,
    required Map<String, dynamic> responseSchema,
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
            // Structured Output の指定
            'response_format': {
              'type': 'json_schema',
              'json_schema': {
                'name': 'response',
                'strict': true,
                'schema': responseSchema,
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('OpenAI API error: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenAI API: no choices in response: ${res.body}');
    }
    final content = choices[0]['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('OpenAI API: empty content in response');
    }
    return jsonDecode(content) as Map<String, dynamic>;
  }

  @override
  Future<String?> searchDrinkImage({
    required String name,
    required String category,
  }) async {
    // gpt-4o-mini はウェブ検索不可のため、検索対応モデルを使用
    const searchModel = 'gpt-4o-search-preview';
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    try {
      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': searchModel,
              'max_tokens': 300,
              'messages': [
                {
                  'role': 'user',
                  'content': '$name ($category) の商品画像のURLを1つだけ教えてください。'
                      '画像URLのみを回答してください。説明は不要です。',
                }
              ],
              'temperature': 0.0,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content'] as String? ?? '';
      final urlPattern = RegExp(r'https?://\S+\.(?:jpg|jpeg|png|webp|gif)');
      return urlPattern.firstMatch(content.trim())?.group(0);
    } catch (_) {
      return null;
    }
  }
}
