// ============================================================
// services/ai/ai_service.dart — AIサービス（プロバイダー切り替え口）
// ============================================================

import 'dart:convert';

// import 'openai_provider.dart'; // ChatGPTに切り替えるときはこちらをコメントイン
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ai_provider.dart';
import 'gemini_provider.dart';

class AiService {
  // ── ここを切り替えるだけでプロバイダーが変わる ──────────
  static AiProvider get _provider => GeminiProvider(
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        // ChatGPTに切り替えるときはこう↓
        // OpenAiProvider(apiKey: dotenv.env['OPENAI_API_KEY'] ?? '')
      );

  static Future<Map<String, dynamic>?> fetchRecommendations({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final text = await _provider.generate(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
    );
    return _parseJson(text);
  }

  static Future<Map<String, dynamic>?> fetchExtraPickup({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final text = await _provider.generate(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
    );
    return _parseJson(text);
  }

  static Map<String, dynamic>? _parseJson(String text) {
    try {
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final s = clean.indexOf('{');
      final e = clean.lastIndexOf('}');
      if (s == -1 || e == -1) return null;
      return jsonDecode(clean.substring(s, e + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
