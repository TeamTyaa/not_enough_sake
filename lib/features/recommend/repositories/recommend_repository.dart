// ══════════════════════════════════════════════════════════
// おすすめリポジトリ
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/ai/ai_service.dart';
import '../../../services/db_service.dart';
import '../../../services/prompts/recommend_prompt.dart';
import '../../common/models/taste_profile.dart';
import '../../review/models/review.dart';
import '../models/recs_history_item.dart';
import '../models/recommended_drink.dart';

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

  // ── 履歴保存 ──────────────────────────────────────────
  Future<void> saveToHistory(String uid, RecommendedDrinks recs, DateTime fetchedAt) async {
    await DbService.collection('users/$uid/recsHistory').add({
      'recs': recs.toMap(),
      'fetchedAt': Timestamp.fromDate(fetchedAt),
    });
  }

  Future<List<RecsHistoryItem>> getHistory(String uid) async {
    final snap = await DbService.collection('users/$uid/recsHistory')
        .orderBy('fetchedAt', descending: true)
        .limit(30)
        .get();
    return snap.docs
        .map((d) => RecsHistoryItem.fromMap(d.id, d.data()))
        .toList();
  }

  Future<Map<String, dynamic>?> fetchExtra({
    required String tier,
    required TasteProfile taste,
    required List<Review> history,
    required List<String> genres,
    required List<String> excludeNames,
  }) async {
    final tasteMsg = 'sweet:${taste.sweet} body:${taste.body} aroma:${taste.aroma} '
        'finish:${taste.finish} kick:${taste.kick}';
    var msg = '$tasteMsg\n価格帯: $tier';
    if (history.isNotEmpty) {
      msg += '\n直近レビュー: ${history.take(3).map((h) => h.name).join('、')}';
    }
    if (excludeNames.isNotEmpty) {
      msg += '\n以下は提案済みのため除外してください: ${excludeNames.join('、')}'; // ← 追加
    }
    return await AiService.fetchExtraPickup(
      systemPrompt: buildExtraSystemPrompt(genres),
      userMessage: msg,
    );
  }
}
