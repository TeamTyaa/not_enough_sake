// ============================================================
// providers/app_providers.dart — Riverpod プロバイダー群
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/mock_db.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'dart:math' show sqrt;

// ══════════════════════════════════════════════════════════
// 認証プロバイダー
// ══════════════════════════════════════════════════════════
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final BlockedUser? blocked;

  const AuthState({
    this.user, this.isLoading = false, this.error, this.blocked,
  });

  AuthState copyWith({
    AppUser? user, bool? isLoading, String? error, BlockedUser? blocked,
    bool clearUser = false, bool clearError = false, bool clearBlocked = false,
  }) => AuthState(
    user:      clearUser    ? null   : user      ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error:     clearError   ? null   : error     ?? this.error,
    blocked:   clearBlocked ? null   : blocked   ?? this.blocked,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // TODO: Firebase実装時 → Firebase Auth に差し替え
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // モック: 固定ユーザー
      const mockUid = 'mock_uid_123';

      // ブラックリストチェック
      if (MockDb.isBlacklisted(mockUid)) {
        state = state.copyWith(
          isLoading: false,
          error: 'このアカウントはご利用いただけません。',
        );
        return;
      }

      // 未成年ブロックチェック
      final blocked = MockDb.getBlocked(mockUid);
      if (blocked != null) {
        final birthday = DateTime.tryParse(blocked.birthday);
        if (birthday != null) {
          final turnsAdult = DateTime(
            birthday.year + 20, birthday.month, birthday.day);
          if (DateTime.now().isBefore(turnsAdult)) {
            state = state.copyWith(isLoading: false, blocked: blocked);
            return;
          }
        }
      }

      // プロフィール取得
      final user = MockDb.getUser(mockUid);
      state = state.copyWith(isLoading: false, user: user, clearBlocked: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false, error: 'ログインに失敗しました: $e',
      );
    }
  }

  Future<void> saveProfile(AppUser user) async {
    await MockDb.setUser(user);
    state = state.copyWith(user: user);
  }

  Future<void> updateUser(AppUser user) async {
    await MockDb.setUser(user);
    state = state.copyWith(user: user);
  }

  Future<void> signOut() async {
    state = const AuthState();
  }

  Future<void> deleteAccount(String uid) async {
    await MockDb.deleteUserData(uid);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

// ══════════════════════════════════════════════════════════
// レビュー・お気に入りプロバイダー
// ══════════════════════════════════════════════════════════
class ReviewsNotifier extends StateNotifier<List<DrinkReview>> {
  final String uid;
  ReviewsNotifier(this.uid) : super([]) { _load(); }

  void _load() {
    state = MockDb.getReviews(uid);
  }

  Future<void> addReview(DrinkReview r) async {
    final id = await MockDb.addReview(uid, r);
    state = [DrinkReview.fromMap(id, r.toMap()), ...state];
  }
}

final reviewsProvider = StateNotifierProvider.family<ReviewsNotifier, List<DrinkReview>, String>(
  (_, uid) => ReviewsNotifier(uid),
);

class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  final String uid;
  FavoritesNotifier(this.uid) : super([]) { _load(); }

  void _load() {
    state = MockDb.getFavorites(uid);
  }

  Future<void> setFavorites(List<FavoriteItem> favs) async {
    await MockDb.setFavorites(uid, favs);
    state = favs;
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setFavorites(list);
  }
}

final favoritesProvider = StateNotifierProvider.family<FavoritesNotifier, List<FavoriteItem>, String>(
  (_, uid) => FavoritesNotifier(uid),
);

// ══════════════════════════════════════════════════════════
// トークンプロバイダー
// ══════════════════════════════════════════════════════════
class TokenNotifier extends StateNotifier<TokenBalance> {
  final String uid;
  TokenNotifier(this.uid) : super(const TokenBalance()) { _load(); }

  void _load() {
    state = MockDb.getTokens(uid);
  }

  Future<void> addFree(int amount) async {
    final next = state.copyWith(free: state.free + amount);
    await MockDb.setTokens(uid, next);
    state = next;
  }

  Future<bool> spendFree(int amount) async {
    if (state.free < amount) return false;
    final next = state.copyWith(free: state.free - amount);
    await MockDb.setTokens(uid, next);
    state = next;
    return true;
  }

  Future<bool> spendPaid(int amount) async {
    if (state.paid < amount) return false;
    final next = state.copyWith(paid: state.paid - amount);
    await MockDb.setTokens(uid, next);
    state = next;
    return true;
  }

  Future<void> addPaid(int amount) async {
    final next = state.copyWith(paid: state.paid + amount);
    await MockDb.setTokens(uid, next);
    state = next;
  }
}

final tokenProvider = StateNotifierProvider.family<TokenNotifier, TokenBalance, String>(
  (_, uid) => TokenNotifier(uid),
);

// ══════════════════════════════════════════════════════════
// おすすめプロバイダー
// ══════════════════════════════════════════════════════════
class RecsState {
  final Map<String, dynamic>? recs; // {low:{...}, mid:{...}, high:{...}}
  final List<Map<String, dynamic>> extraRecs;
  final Map<String, bool> done;
  final bool isLoading;
  final String? error;

  const RecsState({
    this.recs, this.extraRecs = const [], this.done = const {},
    this.isLoading = false, this.error,
  });

  RecsState copyWith({
    Map<String, dynamic>? recs, List<Map<String, dynamic>>? extraRecs,
    Map<String, bool>? done, bool? isLoading, String? error,
    bool clearError = false,
  }) => RecsState(
    recs:      recs      ?? this.recs,
    extraRecs: extraRecs ?? this.extraRecs,
    done:      done      ?? this.done,
    isLoading: isLoading ?? this.isLoading,
    error:     clearError ? null : error ?? this.error,
  );
}

class RecsNotifier extends StateNotifier<RecsState> {
  final String uid;
  final List<String> genres;

  RecsNotifier(this.uid, this.genres) : super(const RecsState()) { _loadCache(); }

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
        msg += '\n\nレビュー履歴:\n' + history.take(6).map((h) =>
          '・${h.name}（${h.tier}）sweet:${h.sliders.sweet} '
          'body:${h.sliders.body} 「${h.text}」'
        ).join('\n');
      }
      final result = await ApiService.fetchRecommendations(
        systemPrompt: buildRecSystemPrompt(genres),
        userMessage: msg,
      );
      if (result != null &&
          result.containsKey('low') &&
          result.containsKey('mid') &&
          result.containsKey('high')) {
        final next = state.copyWith(
          recs: result, done: {}, isLoading: false, clearError: true,
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
        msg += '\n直近レビュー: ' + history.take(3).map((h) => h.name).join('、');
      }
      final result = await ApiService.fetchExtraPickup(
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

// ══════════════════════════════════════════════════════════
// 飲み会掲示板プロバイダー
// ══════════════════════════════════════════════════════════
class PostsNotifier extends StateNotifier<List<NomikaiPost>> {
  PostsNotifier() : super([]) { _load(); }

  void _load() {
    state = MockDb.getPosts();
  }

  Future<void> addPost(NomikaiPost post) async {
    final id = await MockDb.addPost(post);
    state = [NomikaiPost.fromMap(id, post.toMap()), ...state];
  }

  Future<void> updatePost(NomikaiPost post) async {
    await MockDb.updatePost(post);
    state = state.map((p) => p.id == post.id ? post : p).toList();
  }

  NomikaiPost? findById(String id) {
    try { return state.firstWhere((p) => p.id == id); }
    catch (_) { return null; }
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, List<NomikaiPost>>(
  (_) => PostsNotifier(),
);

// ══════════════════════════════════════════════════════════
// お知らせプロバイダー
// ══════════════════════════════════════════════════════════
class NoticesState {
  final List<AppNotice> all;
  final List<String> readIds;

  const NoticesState({this.all = const [], this.readIds = const []});

  List<AppNotice> get active {
    final today = DateTime.now();
    return all.where((n) => n.isActive(today)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AppNotice> get unread =>
    active.where((n) => !readIds.contains(n.id)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  NoticesState copyWith({List<AppNotice>? all, List<String>? readIds}) =>
    NoticesState(all: all ?? this.all, readIds: readIds ?? this.readIds);
}

class NoticesNotifier extends StateNotifier<NoticesState> {
  NoticesNotifier() : super(const NoticesState()) { _load(); }

  void _load() {
    final notices = MockDb.getNotices();
    final readIds = MockDb.getReadNoticeIds();
    state = NoticesState(all: notices, readIds: readIds);
  }

  Future<void> markRead(String id) async {
    if (state.readIds.contains(id)) return;
    final next = [...state.readIds, id];
    await MockDb.setReadNoticeIds(next);
    state = state.copyWith(readIds: next);
  }
}

final noticesProvider = StateNotifierProvider<NoticesNotifier, NoticesState>(
  (_) => NoticesNotifier(),
);

// ══════════════════════════════════════════════════════════
// 好みタステプロバイダー（合成）
// ══════════════════════════════════════════════════════════
final myTasteProvider = Provider.family<TasteProfile, (TasteProfile, List<DrinkReview>)>(
  (_, args) {
    final base    = args.$1;
    final reviews = args.$2;
    if (reviews.length < kReviewThreshold) return base;
    final avg = TasteProfile.average(reviews.map((r) => r.sliders).toList());
    return TasteProfile(
      sweet:  ((base.sweet  + avg.sweet)  / 2).round(),
      body:   ((base.body   + avg.body)   / 2).round(),
      aroma:  ((base.aroma  + avg.aroma)  / 2).round(),
      finish: ((base.finish + avg.finish) / 2).round(),
      kick:   ((base.kick   + avg.kick)   / 2).round(),
    );
  },
);
