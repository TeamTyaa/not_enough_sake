// ══════════════════════════════════════════════════════════
// おすすめプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api/claude_api.dart';
import '../../../services/mock_db.dart';
import '../../../services/prompts/recommendation_prompt.dart';
import '../../common/models/taste_profile.dart';
import '../../review/models/drink_review.dart';

class RecsState {
  final Map<String, dynamic>? recs; // {low:{...}, mid:{...}, high:{...}}
  final List<Map<String, dynamic>> extraRecs;
  final Map<String, bool> done;
  final bool isLoading;
  final String? error;

  const RecsState({
    this.recs,
    this.extraRecs = const [],
    this.done = const {},
    this.isLoading = false,
    this.error,
  });

  RecsState copyWith({
    Map<String, dynamic>? recs,
    List<Map<String, dynamic>>? extraRecs,
    Map<String, bool>? done,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      RecsState(
        recs: recs ?? this.recs,
        extraRecs: extraRecs ?? this.extraRecs,
        done: done ?? this.done,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class RecsNotifier extends StateNotifier<RecsState> {
  final String uid;
  final List<String> genres;

  RecsNotifier(this.uid, this.genres) : super(const RecsState()) {
    _loadCache();
  }

  void _loadCache() {
    final cached = MockDb.getRecsCache(uid);
    if (cached != null) {
      state = RecsState(
        recs: cached['recs'] as Map<String, dynamic>?,
        done: Map<String, bool>.from(cached['done'] ?? {}),
      );
    }
  }

  Future<void> fetchRecs(TasteProfile taste, List<DrinkReview> history) async {
    state = state.copyWith(isLoading: true, clearError: true, extraRecs: []);
    try {
      final tasteMsg = 'good preference:sweet:${taste.sweet} body:${taste.body} '
          'aroma:${taste.aroma} finish:${taste.finish} kick:${taste.kick}';
      var msg = '私の好み: $tasteMsg';
      if (history.isNotEmpty) {
        msg += '\n\nレビュー履歴:\n${history.take(6).map((h) => '・${h.name}（${h.tier}）sweet:${h.sliders.sweet} '
            'body:${h.sliders.body} 「${h.text}」').join('\n')}';
      }
      final result = await ClaudeApi.fetchRecommendations(
        systemPrompt: buildRecSystemPrompt(genres),
        userMessage: msg,
      );
      if (result != null && result.containsKey('low') && result.containsKey('mid') && result.containsKey('high')) {
        final next = state.copyWith(
          recs: result,
          done: {},
          isLoading: false,
          clearError: true,
        );
        state = next;
        await MockDb.setRecsCache(uid, {'recs': result, 'done': {}});
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'おすすめの取得に失敗しました。再試行してください。',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'おすすめの取得に失敗しました: $e',
      );
    }
  }

  void markDone(String tierKey) {
    final next = {...state.done, tierKey: true};
    state = state.copyWith(done: next);
    MockDb.setRecsCache(uid, {'recs': state.recs, 'done': next});
  }

  Future<void> fetchExtraPickup({
    required String tier,
    required TasteProfile taste,
    required List<DrinkReview> history,
    required List<String> genres,
  }) async {
    try {
      final tasteMsg = 'sweet:${taste.sweet} body:${taste.body} '
          'aroma:${taste.aroma} finish:${taste.finish} kick:${taste.kick}';
      var msg = '$tasteMsg\n価格帯: $tier';
      if (history.isNotEmpty) {
        msg += '\n直近レビュー: ${history.take(3).map((h) => h.name).join('、')}';
      }
      final result = await ClaudeApi.fetchExtraPickup(
        systemPrompt: buildExtraSystemPrompt(genres),
        userMessage: msg,
      );
      if (result != null && result.containsKey('name')) {
        state = state.copyWith(extraRecs: [...state.extraRecs, result]);
      }
    } catch (e) {
      // 静かに失敗
    }
  }
}

final recsProvider = StateNotifierProvider.family<RecsNotifier, RecsState, (String, List<String>)>(
  (_, args) => RecsNotifier(args.$1, args.$2),
);
