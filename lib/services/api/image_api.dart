// ============================================================
// 画像検索 APIクライアント
// ============================================================

import 'api_client.dart';

class ImageApi {
  // ── 画像検索 ─────────────────────────────────────────────
  static Future<String?> fetchDrinkImage(String name, String category) async {
    try {
      final result = await ApiClient.call(
        '/api/image',
        {'q': '$name $category お酒 ボトル'},
        retries: 1,
      );
      return result['imageUrl'] as String?;
    } catch (_) {
      return null;
    }
  }
}
