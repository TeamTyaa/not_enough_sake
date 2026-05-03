// ============================================================
// AIサービス
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ai_provider.dart';
import 'gemini_provider.dart';
// import 'openai_provider.dart'; // ChatGPTに切り替えるときはコメントイン

class AiService {
  static AiProvider get _provider {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    assert(key.isNotEmpty, 'GEMINI_API_KEY が .env に設定されていません');
    return GeminiProvider(
      apiKey: key,
      // ChatGPTに切り替えるときはこう↓
      // OpenAiProvider(apiKey: dotenv.env['OPENAI_API_KEY'] ?? '')
    );
  }

  static Future<String?> searchDrinkImage({
    required String name,
    required String category,
  }) async {
    try {
      return await _provider.searchDrinkImage(name: name, category: category);
    } catch (e) {
      debugPrint('[AiService] searchDrinkImage failed: $e');
      return null;
    }
  }

  // ── レコメンド（3本） ─────────────────────────────────
  static Future<Map<String, dynamic>?> fetchRecommendations({
    required String systemPrompt,
    required String userMessage,
  }) async {
    try {
      return await _provider.generateJson(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        responseSchema: _recSchema,
      );
    } catch (e) {
      debugPrint('[AiService] fetchRecommendations failed: $e');
      return null;
    }
  }

  // ── 追加ピックアップ（1本） ───────────────────────────
  static Future<Map<String, dynamic>?> fetchExtraPickup({
    required String systemPrompt,
    required String userMessage,
  }) async {
    try {
      return await _provider.generateJson(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        responseSchema: _extraSchema,
      );
    } catch (e) {
      debugPrint('[AiService] fetchExtraPickup failed: $e');
      return null;
    }
  }

  // ── レコメンド用スキーマ（low/mid/high 各1本） ────────
  static const Map<String, dynamic> _recSchema = {
    'type': 'object',
    'properties': {
      'low': {r'$ref': '#/definitions/drink'},
      'mid': {r'$ref': '#/definitions/drink'},
      'high': {r'$ref': '#/definitions/drink'},
    },
    'required': ['low', 'mid', 'high'],
    'definitions': {
      'drink': _drinkSchema,
    },
  };

  // ── 追加ピックアップ用スキーマ（1本） ─────────────────
  static const Map<String, dynamic> _extraSchema = _drinkSchema;

  // ── お酒1本のスキーマ（共通） ─────────────────────────
  static const Map<String, dynamic> _drinkSchema = {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': '銘柄名'},
      'category': {'type': 'string', 'description': 'お酒のカテゴリ'},
      'description': {'type': 'string', 'description': '2〜3文の説明'},
      'profile': {'type': 'string', 'description': '味わいの特徴'},
      'occasion': {'type': 'string', 'description': '飲むシーン'},
      'officialUrl': {'type': 'string', 'description': '酒蔵の公式URL（不明な場合は空文字）'},
    },
    'required': ['name', 'category', 'description', 'profile', 'occasion'],
  };
}
