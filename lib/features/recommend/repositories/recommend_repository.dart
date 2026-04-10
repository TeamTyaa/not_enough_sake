// ══════════════════════════════════════════════════════════
// おすすめリポジトリ
// ══════════════════════════════════════════════════════════

import '../../../services/ai/ai_service.dart';
import '../../../services/db_service.dart';
import '../../../services/prompts/recommend_prompt.dart';
import '../../common/models/taste_profile.dart';
import '../../review/models/review.dart';

class RecommendRepository {
  Future<Map<String, dynamic>?> getCache(String uid) async {
    final snap = await DbService.doc('users/$uid/recs/current').get();
    if (!snap.exists) return null;
    return snap.data()! as Map<String, dynamic>;
  }

  Future<void> setCache(String uid, Map<String, dynamic> data) async {
    await DbService.doc('users/$uid/recs/current').set(data);
  }

  Future<Map<String, dynamic>?> fetchRecs({
    required TasteProfile taste,
    required List<Review> history,
    required List<String> genres,
  }) async {
    final tasteMsg =
        'sweet:${taste.sweet} body:${taste.body} aroma:${taste.aroma} finish:${taste.finish} kick:${taste.kick}';

    var msg = '私の好み: $tasteMsg';

    if (history.isNotEmpty) {
      msg += '\nレビュー履歴:\n${history.take(5).map((h) => h.name).join('\n')}';
    }

    return await AiService.fetchRecommendations(
      systemPrompt: buildRecSystemPrompt(genres),
      userMessage: msg,
    );
  }

  Future<Map<String, dynamic>?> fetchExtra({
    required String tier,
    required TasteProfile taste,
    required List<Review> history,
    required List<String> genres,
  }) async {
    final tasteMsg = 'sweet:${taste.sweet} body:${taste.body} aroma:${taste.aroma} '
        'finish:${taste.finish} kick:${taste.kick}';
    var msg = '$tasteMsg\n価格帯: $tier';
    if (history.isNotEmpty) {
      msg += '\n直近レビュー: ${history.take(3).map((h) => h.name).join('、')}';
    }
    return await AiService.fetchExtraPickup(
      systemPrompt: buildExtraSystemPrompt(genres),
      userMessage: msg,
    );
  }
}
