// ══════════════════════════════════════════════════════════
// おすすめプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/models/taste_profile.dart';
import '../../review/models/review.dart';
import '../models/recommended_drink.dart';
import '../repositories/recommend_repository.dart';

class RecsState {
  final RecommendedDrinks? recs;
  final List<RecommendedDrink> extraRecs;
  final Map<String, bool> done;
  final bool isLoading;
  final String? error;
  final DateTime? fetchedAt;

  const RecsState({
    this.recs,
    this.extraRecs = const [],
    this.done = const {},
    this.isLoading = false,
    this.error,
    this.fetchedAt,
  });

  /// 12時間経過しているか（まだ取得したことがない場合は取得可能）
  bool get canFetch {
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt!) >= const Duration(hours: 12);
  }

  /// 次回取得までの残り時間
  Duration get cooldownRemaining {
    if (fetchedAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(fetchedAt!);
    final remaining = const Duration(hours: 12) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  RecsState copyWith({
    RecommendedDrinks? recs,
    List<RecommendedDrink>? extraRecs,
    Map<String, bool>? done,
    bool? isLoading,
    String? error,
    DateTime? fetchedAt,
    bool clearError = false,
    bool clearFetchedAt = false,
  }) =>
      RecsState(
        recs: recs ?? this.recs,
        extraRecs: extraRecs ?? this.extraRecs,
        done: done ?? this.done,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        fetchedAt: clearFetchedAt ? null : fetchedAt ?? this.fetchedAt,
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
  Future<void> _loadCache() async {
    try {
      final cached = await _repository.getCache(uid);
      if (cached != null && cached['recs'] != null) {
        DateTime? fetchedAt;
        final ts = cached['fetchedAt'];
        if (ts is Timestamp) fetchedAt = ts.toDate();

        state = RecsState(
          recs: RecommendedDrinks.fromMap(cached['recs'] as Map<String, dynamic>),
          done: Map<String, bool>.from(cached['done'] ?? {}),
          fetchedAt: fetchedAt,
        );
      }
    } catch (_) {}
  }

  // ── おすすめ取得（12時間クールダウン付き） ────────────
  Future<void> fetchRecs(TasteProfile taste, List<Review> history) async {
    if (!state.canFetch) return;

    state = state.copyWith(isLoading: true, clearError: true, extraRecs: []);
    try {
      final result = await _repository.fetchRecs(taste: taste, history: history, genres: genres);

      if (result != null && result.containsKey('low') && result.containsKey('mid') && result.containsKey('high')) {
        final drinks = RecommendedDrinks.fromMap(result);
        final now = DateTime.now();

        state = state.copyWith(
          recs: drinks,
          done: {},
          isLoading: false,
          fetchedAt: now,
          clearError: true,
        );

        await _repository.setCache(uid, {
          'recs': drinks.toMap(),
          'done': {},
          'fetchedAt': Timestamp.fromDate(now),
        });
        await _repository.saveToHistory(uid, drinks, now);
      } else {
        state = state.copyWith(isLoading: false, error: 'おすすめの取得に失敗しました。再試行してください。');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'おすすめの取得に失敗しました: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── 完了フラグ ────────────────────────────────────────
  void markDone(String tierKey) {
    if (state.recs == null) return; // recs がない状態では書き込まない
    final next = {...state.done, tierKey: true};
    state = state.copyWith(done: next);
    _repository.setCache(uid, {
      'recs': state.recs!.toMap(),
      'done': next,
      if (state.fetchedAt != null) 'fetchedAt': Timestamp.fromDate(state.fetchedAt!),
    });
  }

  // ── 追加ピックアップ（クールダウン対象外） ────────────
  // 成功時 true、失敗時 false を返す（呼び出し元でトークン返金の判断に使う）
  Future<bool> fetchExtraPickup({
    required String tier,
    required TasteProfile taste,
    required List<Review> history,
    required List<String> genres,
  }) async {
    // 現在のおすすめ＋追加ピックアップの名前を収集して除外リストに
    final excludeNames = [
      ...?state.recs?.all.map((d) => d.name),
      ...state.extraRecs.map((d) => d.name),
    ];

    try {
      final result = await _repository.fetchExtra(
        tier: tier,
        taste: taste,
        history: history,
        genres: genres,
        excludeNames: excludeNames,
      );
      if (result != null && result.containsKey('name')) {
        final drink = RecommendedDrink.fromMap(result, result['priceKey'] as String? ?? tier);
        state = state.copyWith(extraRecs: [...state.extraRecs, drink]);
        return true;
      } else {
        state = state.copyWith(error: '追加ピックアップの取得に失敗しました。再試行してください。');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: '追加ピックアップの取得に失敗しました: $e');
      return false;
    }
  }
}

final recsProvider = StateNotifierProvider.family<RecsNotifier, RecsState, (String, List<String>)>(
  (_, args) => RecsNotifier(args.$1, args.$2),
);
