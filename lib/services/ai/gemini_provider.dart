// ============================================================
// Geminiプロバイダ
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

class GeminiProvider implements AiProvider {
  final String apiKey;
  final String model;

  GeminiProvider({
    required this.apiKey,
    this.model = 'gemini-1.5-flash-002',
  });

  @override
  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userMessage,
    required Map<String, dynamic> responseSchema,
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
              // Structured Output の指定
              'responseMimeType': 'application/json',
              'responseSchema': responseSchema,
            },
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Gemini API error: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // Structured Output 指定時はテキストが必ず有効なJSONで返ってくる
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    return jsonDecode(text) as Map<String, dynamic>;
  }
}
