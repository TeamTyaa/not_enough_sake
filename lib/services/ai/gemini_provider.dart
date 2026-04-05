// ============================================================
// services/ai/gemini_provider.dart — Gemini実装
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

class GeminiProvider implements AiProvider {
  final String apiKey;

  // モデル選択
  // gemini-1.5-flash-002 → 安くて速い（レコメンド用途に十分）
  // gemini-1.5-pro-002   → 高精度（必要に応じて切り替え）
  final String model;

  GeminiProvider({
    required this.apiKey,
    this.model = 'gemini-1.5-flash-002',
  });

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1200,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta'
      '/models/$model:generateContent?key=$apiKey',
    );

    final res = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': systemPrompt}
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': userMessage}
                ],
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': maxTokens,
            },
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Gemini API error: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
