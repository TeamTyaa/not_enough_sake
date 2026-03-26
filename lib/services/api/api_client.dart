// ============================================================
// APIクライアント
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

// TODO: AIを差し替え
const String kCloudRunBaseUrl = 'https://YOUR_CLOUD_RUN_URL';
const int kMaxRetry = 2;

class ApiClient {
  static Future<Map<String, dynamic>> call(
    String endpoint,
    Map<String, dynamic> body, {
    int retries = kMaxRetry,
  }) async {
    if (kCloudRunBaseUrl.contains('YOUR_')) {
      // 開発用: Anthropic APIに直接アクセス
      if (endpoint == '/api/claude') return ApiClient.callClaudeDirect(body);
      if (endpoint == '/api/image') return {'imageUrl': null};
      throw Exception('Cloud Run URL が未設定です');
    }

    Exception? lastError;
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse('$kCloudRunBaseUrl$endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));

        if (res.statusCode != 200) {
          Map<String, dynamic> err = {};
          try {
            err = jsonDecode(res.body);
          } catch (_) {}
          throw Exception(err['error'] ?? 'HTTP ${res.statusCode}');
        }
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e) {
        lastError = Exception(e.toString());
        if (attempt < retries) {
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }
    throw lastError!;
  }

  // Anthropic APIに直接アクセス（開発用フォールバック）
  static Future<Map<String, dynamic>> callClaudeDirect(Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            // 開発時のみ。本番はCloud Run経由にすること
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-sonnet-4-20250514',
            'max_tokens': body['max_tokens'] ?? 1200,
            'system': body['system'],
            'messages': body['messages'],
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Claude API error: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = data['content'] as List;
    final text = content.whereType<Map>().firstWhere((e) => e['type'] == 'text', orElse: () => {})['text'] ?? '';
    return {'text': text};
  }
}
