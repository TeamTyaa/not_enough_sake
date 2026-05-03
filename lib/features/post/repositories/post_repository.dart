// ══════════════════════════════════════════════════════════
// 投稿リポジトリ
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/db_service.dart';
import '../models/intent_user.dart';
import '../models/nomikai_post.dart';
import '../models/nomikai_rating.dart';
import '../models/post_comment.dart';
import '../models/post_status.dart';

class PostRepository {
  // ── 初回・リフレッシュ取得 ────────────────────────────
  Future<PostPage> getFirstPage(int pageSize) async {
    final snap = await DbService.collection('nomikaiPosts')
        .where('status', whereIn: [postStatusToInt(PostStatus.open), postStatusToInt(PostStatus.confirmed)])
        .orderBy('createdAt', descending: true)
        .limit(pageSize)
        .get();

    final posts = snap.docs.map((d) => NomikaiPost.fromMap(d.id, d.data())).toList();

    return PostPage(
      posts: posts,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == pageSize,
    );
  }

  // ── 追加取得（無限スクロール） ────────────────────────
  Future<PostPage> getNextPage({
    required DocumentSnapshot lastDoc,
    required int pageSize,
  }) async {
    final snap = await DbService.collection('nomikaiPosts')
        .where('status', whereIn: [postStatusToInt(PostStatus.open), postStatusToInt(PostStatus.confirmed)])
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(pageSize)
        .get();

    final posts = snap.docs.map((d) => NomikaiPost.fromMap(d.id, d.data())).toList();

    return PostPage(
      posts: posts,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == pageSize,
    );
  }

  // ── 投稿追加 ──────────────────────────────────────────
  Future<String> addPost(NomikaiPost post) async {
    final ref = await DbService.collection('nomikaiPosts').add({
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ── 投稿更新（ステータス変更など） ───────────────────
  // intents / ratings の変更には addIntent / removeIntent / addRating を使うこと
  Future<void> updatePost(NomikaiPost post) async {
    await DbService.doc('nomikaiPosts/${post.id}').update(post.toMap());
  }

  // ── 参加意志を追加（transaction で競合防止） ─────────
  Future<void> addIntent(
    String postId,
    IntentUser intent, {
    required int minAttendees,
  }) async {
    final docRef = DbService.doc('nomikaiPosts/$postId');
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()! as Map<String, dynamic>;

      final intents = ((data['intents'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(IntentUser.fromMap)
          .toList();

      // すでに登録済みなら何もしない
      if (intents.any((i) => i.uid == intent.uid)) return;
      intents.add(intent);

      final currentStatus = postStatusFromInt((data['status'] as int?) ?? 0) ?? PostStatus.open;
      final newStatus = intents.length >= minAttendees && currentStatus == PostStatus.open
          ? PostStatus.confirmed
          : currentStatus;

      tx.update(docRef, {
        'intents': intents.map((e) => e.toMap()).toList(),
        'status': postStatusToInt(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── 参加意志をキャンセル（transaction で競合防止） ───
  Future<void> removeIntent(String postId, String uid) async {
    final docRef = DbService.doc('nomikaiPosts/$postId');
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()! as Map<String, dynamic>;

      final intents = ((data['intents'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(IntentUser.fromMap)
          .where((i) => i.uid != uid)
          .toList();

      final minAttendees = (data['minAttendees'] as int?) ?? 0;
      final currentStatus = postStatusFromInt((data['status'] as int?) ?? 0) ?? PostStatus.open;
      // confirmed → open への格下げ（キャンセルで minAttendees を下回った場合）
      final newStatus = (currentStatus == PostStatus.confirmed && intents.length < minAttendees)
          ? PostStatus.open
          : currentStatus;

      tx.update(docRef, {
        'intents': intents.map((e) => e.toMap()).toList(),
        'status': postStatusToInt(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── 評価を追加（arrayUnion で競合防止） ──────────────
  Future<void> addRating(String postId, NomikaiRating rating) async {
    await DbService.doc('nomikaiPosts/$postId').update({
      'ratings': FieldValue.arrayUnion([rating.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── コメント ──────────────────────────────────────────
  Future<List<PostComment>> getComments(String postId) async {
    final snap = await DbService.collection('nomikaiPosts/$postId/comments').orderBy('createdAt').get();
    return snap.docs.map((d) => PostComment.fromMap(d.id, d.data())).toList();
  }

  Future<String> addComment(String postId, PostComment c) async {
    final ref = await DbService.collection('nomikaiPosts/$postId/comments').add(c.toMap());
    return ref.id;
  }
}

// ── ページ取得結果 ────────────────────────────────────────
class PostPage {
  final List<NomikaiPost> posts;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PostPage({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
  });
}
