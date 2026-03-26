// ============================================================
// services/mock_db.dart — SharedPreferences ベースのモックDB
// TODO: Firebase実装時 → 各メソッドをFirestore SDKに差し替え
// ============================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/models/app_user.dart';
import '../features/auth/models/blocked_user.dart';
import '../features/notice/models/app_notice.dart';
import '../features/post/models/nomikai_post.dart';
import '../features/post/models/post_comment.dart';
import '../features/post/models/report_data.dart';
import '../features/review/models/drink_review.dart';
import '../features/review/models/favorite_item.dart';
import '../features/token/models/token_balance.dart';

class MockDb {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedNotices();
  }

  static SharedPreferences get prefs {
    assert(_prefs != null, 'MockDb.init() を先に呼んでください');
    return _prefs!;
  }

  // ── 内部ヘルパー ──────────────────────────────────────────
  static Map<String, dynamic>? _get(String key) {
    final s = prefs.getString('fb_$key');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> _set(String key, Map<String, dynamic> data) async {
    await prefs.setString('fb_$key', jsonEncode(data));
  }

  static List<Map<String, dynamic>> _getCollection(String path) {
    final prefix = 'fb_$path/';
    return prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .map((k) {
          final s = prefs.getString(k);
          if (s == null) return null;
          final id = k.substring(prefix.length);
          final data = jsonDecode(s) as Map<String, dynamic>;
          return {'_id': id, ...data};
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<String> _add(String path, Map<String, dynamic> data) async {
    final id = '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
        '${(DateTime.now().microsecond % 1000).toRadixString(36)}';
    await _set('$path/$id', data);
    return id;
  }

  // ── お知らせ初期データ ────────────────────────────────────
  static Future<void> _seedNotices() async {
    if (prefs.getBool('fb_notices_seeded') == true) return;
    final notices = [
      {
        '_id': 'n1',
        'title': '🎉 酒語りＮ へようこそ！',
        'body': 'AIがあなた好みのお酒を探します。まずはレビューを5本貯めると飲み会掲示板が解放されます。',
        'startAt': '2026-01-01',
        'endAt': '2099-12-31',
        'createdAt': '2026-01-01',
      },
      {
        '_id': 'n2',
        'title': '📢 公式URLの承認機能を追加しました',
        'body': 'お酒の公式サイトURLをみんなで確認して承認できるようになりました。3人が承認すると全ユーザーに表示されます。',
        'startAt': '2026-03-01',
        'endAt': '2026-06-30',
        'createdAt': '2026-03-01',
      },
    ];
    for (final n in notices) {
      final id = n['_id'] as String;
      final data = Map<String, dynamic>.from(n)..remove('_id');
      await prefs.setString('fb_notices/$id', jsonEncode(data));
    }
    await prefs.setBool('fb_notices_seeded', true);
  }

  // ══════════════════════════════════════════════════════════
  // ユーザー
  // ══════════════════════════════════════════════════════════
  static AppUser? getUser(String uid) {
    final m = _get('users/$uid');
    if (m == null) return null;
    return AppUser.fromMap(uid, m);
  }

  static Future<void> setUser(AppUser user) async {
    await _set('users/${user.uid}', user.toMap());
  }

  // ── 未成年ブロック ────────────────────────────────────────
  static BlockedUser? getBlocked(String uid) {
    final m = _get('blockedUsers/$uid');
    if (m == null) return null;
    return BlockedUser.fromMap(uid, m);
  }

  static Future<void> setBlocked(BlockedUser b) async {
    await _set('blockedUsers/${b.uid}', b.toMap());
  }

  // ── ブラックリスト ────────────────────────────────────────
  static bool isBlacklisted(String uid) {
    return _get('blacklist/$uid') != null;
  }

  // ══════════════════════════════════════════════════════════
  // レビュー
  // ══════════════════════════════════════════════════════════
  static List<DrinkReview> getReviews(String uid) {
    return _getCollection('users/$uid/reviews').map((m) {
      final id = m['_id'] as String;
      final data = Map<String, dynamic>.from(m)..remove('_id');
      return DrinkReview.fromMap(id, data);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<String> addReview(String uid, DrinkReview r) async {
    return _add('users/$uid/reviews', r.toMap());
  }

  // ══════════════════════════════════════════════════════════
  // お気に入り
  // ══════════════════════════════════════════════════════════
  static List<FavoriteItem> getFavorites(String uid) {
    final m = _get('users/$uid/favorites/list');
    if (m == null) return [];
    return (m['items'] as List? ?? []).map((e) => FavoriteItem.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<void> setFavorites(String uid, List<FavoriteItem> favs) async {
    await _set('users/$uid/favorites/list', {'items': favs.map((e) => e.toMap()).toList()});
  }

  // ══════════════════════════════════════════════════════════
  // おすすめキャッシュ
  // ══════════════════════════════════════════════════════════
  static Map<String, dynamic>? getRecsCache(String uid) {
    return _get('users/$uid/recs/current');
  }

  static Future<void> setRecsCache(String uid, Map<String, dynamic> data) async {
    await _set('users/$uid/recs/current', data);
  }

  // ══════════════════════════════════════════════════════════
  // トークン
  // ══════════════════════════════════════════════════════════
  static TokenBalance getTokens(String uid) {
    final m = _get('users/$uid/tokens');
    if (m == null) return const TokenBalance();
    return TokenBalance.fromMap(m);
  }

  static Future<void> setTokens(String uid, TokenBalance t) async {
    await _set('users/$uid/tokens', t.toMap());
  }

  // ══════════════════════════════════════════════════════════
  // 飲み会投稿
  // ══════════════════════════════════════════════════════════
  static List<NomikaiPost> getPosts() {
    return _getCollection('nomikaiPosts').map((m) {
      final id = m['_id'] as String;
      final data = Map<String, dynamic>.from(m)..remove('_id');
      return NomikaiPost.fromMap(id, data);
    }).toList();
  }

  static Future<String> addPost(NomikaiPost post) async {
    return _add('nomikaiPosts', post.toMap());
  }

  static Future<void> updatePost(NomikaiPost post) async {
    await _set('nomikaiPosts/${post.id}', post.toMap());
  }

  // ══════════════════════════════════════════════════════════
  // コメント
  // ══════════════════════════════════════════════════════════
  static List<PostComment> getComments(String postId) {
    return _getCollection('nomikaiPosts/$postId/comments').map((m) {
      final id = m['_id'] as String;
      final data = Map<String, dynamic>.from(m)..remove('_id');
      return PostComment.fromMap(id, data);
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<String> addComment(String postId, PostComment c) async {
    return _add('nomikaiPosts/$postId/comments', c.toMap());
  }

  // ══════════════════════════════════════════════════════════
  // お知らせ
  // ══════════════════════════════════════════════════════════
  static List<AppNotice> getNotices() {
    return _getCollection('notices').map((m) {
      final id = m['_id'] as String;
      final data = Map<String, dynamic>.from(m)..remove('_id');
      return AppNotice.fromMap(id, data);
    }).toList();
  }

  // ══════════════════════════════════════════════════════════
  // 通報
  // ══════════════════════════════════════════════════════════
  static Future<void> addReport(ReportData r) async {
    await _add('reports', r.toMap());
  }

  // ══════════════════════════════════════════════════════════
  // 公式URL承認
  // ══════════════════════════════════════════════════════════
  static Map<String, dynamic>? getDrinkInfo(String name) {
    return _get('drinks/${Uri.encodeComponent(name)}');
  }

  static Future<void> updateDrinkApproval(String name, String uid, String url) async {
    final key = 'drinks/${Uri.encodeComponent(name)}';
    final prev = _get(key) ?? <String, dynamic>{};
    final approvals = List<String>.from(prev['approvals'] ?? []);
    if (!approvals.contains(uid)) approvals.add(uid);
    await _set(key, {
      ...prev,
      'officialUrl': url,
      'approvals': approvals,
      'approvalCount': approvals.length,
    });
  }

  static Future<void> setDrinkVerified(String name, String url) async {
    final key = 'drinks/${Uri.encodeComponent(name)}';
    final prev = _get(key) ?? <String, dynamic>{};
    await _set(key, {...prev, 'status': 'verified', 'officialUrl': url});
  }

  // ══════════════════════════════════════════════════════════
  // アカウント削除
  // ══════════════════════════════════════════════════════════
  static Future<void> deleteUserData(String uid) async {
    final keys = prefs.getKeys().where((k) => k.startsWith('fb_users/$uid') || k.startsWith('fb_nomikai')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  // 既読お知らせ
  static List<String> getReadNoticeIds() {
    return prefs.getStringList('ng_read_notices') ?? [];
  }

  static Future<void> setReadNoticeIds(List<String> ids) async {
    await prefs.setStringList('ng_read_notices', ids);
  }
}
