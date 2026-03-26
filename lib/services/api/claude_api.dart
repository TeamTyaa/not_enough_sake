// ============================================================
// Cloud Run APIクライアント
// ============================================================

import 'dart:convert';

import 'api_client.dart';

class ClaudeApi {
  // ── Claude おすすめ生成 ───────────────────────────────────
  static Future<Map<String, dynamic>?> fetchRecommendations({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final result = await ApiClient.call('/api/claude', {
      'system': systemPrompt,
      'messages': [
        {'role': 'user', 'content': userMessage}
      ],
    });
    final text = result['text'] as String? ?? '';
    return _parseJson(text);
  }

  // ── 追加ピックアップ ─────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchExtraPickup({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final result = await ApiClient.call('/api/claude', {
      'system': systemPrompt,
      'messages': [
        {'role': 'user', 'content': userMessage}
      ],
    });
    final text = result['text'] as String? ?? '';
    return _parseJson(text);
  }

  // ── JSONパーサー ─────────────────────────────────────────
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
