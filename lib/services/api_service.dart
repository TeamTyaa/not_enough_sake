// ============================================================
// services/api_service.dart — Cloud Run APIクライアント
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

// TODO: Cloud Run デプロイ後に差し替え
const String kCloudRunBaseUrl = 'https://YOUR_CLOUD_RUN_URL';
const int    kMaxRetry        = 2;

class ApiService {
  static Future<Map<String, dynamic>> _call(
    String endpoint,
    Map<String, dynamic> body, {
    int retries = kMaxRetry,
  }) async {
    if (kCloudRunBaseUrl.contains('YOUR_')) {
      // 開発用: Anthropic APIに直接アクセス
      if (endpoint == '/api/claude') return _callClaudeDirect(body);
      if (endpoint == '/api/image')  return {'imageUrl': null};
      throw Exception('Cloud Run URL が未設定です');
    }

    Exception? lastError;
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final res = await http.post(
          Uri.parse('$kCloudRunBaseUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));

        if (res.statusCode != 200) {
          Map<String, dynamic> err = {};
          try { err = jsonDecode(res.body); } catch (_) {}
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
  static Future<Map<String, dynamic>> _callClaudeDirect(
      Map<String, dynamic> body) async {
    final res = await http.post(
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
    ).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Claude API error: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = data['content'] as List;
    final text = content.whereType<Map>()
      .firstWhere((e) => e['type'] == 'text', orElse: () => {})['text'] ?? '';
    return {'text': text};
  }

  // ── Claude おすすめ生成 ───────────────────────────────────
  static Future<Map<String, dynamic>?> fetchRecommendations({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final result = await _call('/api/claude', {
      'system': systemPrompt,
      'messages': [{'role': 'user', 'content': userMessage}],
    });
    final text = result['text'] as String? ?? '';
    return _parseJson(text);
  }

  // ── 追加ピックアップ ─────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchExtraPickup({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final result = await _call('/api/claude', {
      'system': systemPrompt,
      'messages': [{'role': 'user', 'content': userMessage}],
    });
    final text = result['text'] as String? ?? '';
    return _parseJson(text);
  }

  // ── 画像検索 ─────────────────────────────────────────────
  static Future<String?> fetchDrinkImage(String name, String category) async {
    try {
      final result = await _call(
        '/api/image',
        {'q': '$name $category お酒 ボトル'},
        retries: 1,
      );
      return result['imageUrl'] as String?;
    } catch (_) {
      return null;
    }
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

// ── おすすめシステムプロンプト生成 ──────────────────────────
String buildRecSystemPrompt(List<String> genres) {
  final gl = genres.join('、');
  return '''あなたはお酒のソムリエです。価格帯ごとに1本ずつ合計3本を提案してください。

スライダー値 -5〜+5（0=ちょうどいい）:
sweet(-5=甘い/+5=辛い) body(-5=軽い/+5=濃厚) aroma(-5=フルーティ/+5=どっしり) finish(-5=すっきり/+5=コク残る) kick(-5=まろやか/+5=キリッと)

ジャンルは必ず以下から: $gl
officialUrlは酒蔵公式URL（不確かならnull）。

JSON形式のみ:
{"low":{"name":"銘柄名","category":"カテゴリ","description":"2〜3文","profile":"味わい","occasion":"シーン","officialUrl":null},"mid":{...},"high":{...}}''';
}

String buildExtraSystemPrompt(List<String> genres) {
  final gl = genres.join('、');
  return '''お酒のソムリエです。ユーザーの好みに合う${gl}の中から1本だけ提案してください。
JSON形式のみ: {"name":"銘柄名","category":"カテゴリ","description":"2〜3文","profile":"味わい","occasion":"シーン","officialUrl":null}''';
}
