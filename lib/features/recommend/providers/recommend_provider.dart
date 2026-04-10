// ══════════════════════════════════════════════════════════
// おすすめプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/models/taste_profile.dart';
import '../../review/models/review.dart';
import '../repositories/recommend_repository.dart';

class RecsState {
  final Map<String, dynamic>? recs;
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

  final _repository = RecommendRepository();

  // ── キャッシュ読み込み ────────────────────────────────
  void _loadCache() async {
    try {
      final cached = await _repository.getCache(uid);
      if (cached != null) {
        state = RecsState(
          recs: cached['recs'] as Map<String, dynamic>?,
          done: Map<String, bool>.from(cached['done'] ?? {}),
        );
      }
    } catch (_) {
      // キャッシュ失敗は無視して続行
    }
  }

  // ── おすすめ取得 ──────────────────────────────────────
  Future<void> fetchRecs(TasteProfile taste, List<Review> history) async {
    state = state.copyWith(isLoading: true, clearError: true, extraRecs: []);
    try {
      final result = await _repository.fetchRecs(
        taste: taste,
        history: history,
        genres: genres,
      );

      if (result != null && result.containsKey('low') && result.containsKey('mid') && result.containsKey('high')) {
        state = state.copyWith(
          recs: result,
          done: {},
          isLoading: false,
          clearError: true,
        );
        await _repository.setCache(uid, {'recs': result, 'done': {}});
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

  // ── 完了フラグ ────────────────────────────────────────
  void markDone(String tierKey) {
    final next = {...state.done, tierKey: true};
    state = state.copyWith(done: next);
    // キャッシュも更新（エラーは無視）
    _repository.setCache(uid, {'recs': state.recs, 'done': next});
  }

  // ── 追加ピックアップ ──────────────────────────────────
  Future<void> fetchExtraPickup({
    required String tier,
    required TasteProfile taste,
    required List<Review> history,
    required List<String> genres,
  }) async {
    try {
      final result = await _repository.fetchExtra(
        tier: tier,
        taste: taste,
        history: history,
        genres: genres,
      );
      if (result != null && result.containsKey('name')) {
        state = state.copyWith(
          extraRecs: [...state.extraRecs, result],
        );
      }
    } catch (_) {
      // 追加ピックアップ失敗は静かに無視
    }
  }
}

final recsProvider = StateNotifierProvider.family<RecsNotifier, RecsState, (String, List<String>)>(
  (_, args) => RecsNotifier(args.$1, args.$2),
);
