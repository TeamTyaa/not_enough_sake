// ══════════════════════════════════════════════════════════
// 投稿リポジトリ
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/db_service.dart';
import '../models/nomikai_post.dart';
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
        .where('status', whereIn: ['open', 'confirmed'])
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc) // カーソルページネーション
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
      'createdAt': FieldValue.serverTimestamp(), // サーバー時刻で管理
    });
    return ref.id;
  }

  // ── 投稿更新 ──────────────────────────────────────────
  Future<void> updatePost(NomikaiPost post) async {
    await DbService.doc('nomikaiPosts/${post.id}').set(post.toMap());
  }

  // ── コメント ──────────────────────────────────────────
  Future<List<PostComment>> getComments(String postId) async {
    final snap = await DbService.collection('nomikaiPosts/$postId/comments').orderBy('createdAt').get();
    return snap.docs.map((d) => PostComment.fromMap(d.data())).toList();
  }

  Future<String> addComment(String postId, PostComment c) async {
    final ref = await DbService.collection('nomikaiPosts/$postId/comments').add(c.toMap());
    return ref.id;
  }
}

// ── ページ取得結果 ────────────────────────────────────────
class PostPage {
  final List<NomikaiPost> posts;
  final DocumentSnapshot? lastDoc; // 次ページ取得のカーソル
  final bool hasMore;

  const PostPage({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
  });
}
