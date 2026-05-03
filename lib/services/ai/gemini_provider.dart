// ============================================================
// Geminiプロバイダ
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_provider.dart';

class GeminiProvider implements AiProvider {
  final String apiKey;
  final String model;

  // 画像検索には grounding が使える最新モデルを使う
  static const _geminiModel = 'gemini-2.0-flash';

  GeminiProvider({
    required this.apiKey,
    this.model = _geminiModel,
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
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini API: no candidates (safety filter?): ${res.body}');
    }
    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini API: no parts in response');
    }
    final text = parts[0]['text'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Gemini API: empty text in response');
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  @override
  Future<String?> searchDrinkImage({
    required String name,
    required String category,
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
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'text': '$name $category の商品画像のURLを1つだけ教えてください。'
                        '画像URLのみを回答してください。説明は不要です。',
                  }
                ],
              }
            ],
            'tools': [
              // Google Search グラウンディングで最新の画像URLを取得
              {'google_search': {}},
            ],
            'generationConfig': {
              'temperature': 0.0, // 再現性を高める
              'maxOutputTokens': 200, // URLだけなので短くてよい
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    final text = (parts[0]['text'] as String? ?? '').trim();

    // レスポンスからURLを抽出
    final urlPattern = RegExp(r'https?://\S+\.(?:jpg|jpeg|png|webp|gif)');
    final match = urlPattern.firstMatch(text);
    return match?.group(0);
  }
}
