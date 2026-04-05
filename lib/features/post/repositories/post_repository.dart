import '../../../services/db_service.dart';
import '../models/nomikai_post.dart';
import '../models/post_comment.dart';

class PostRepository {
  Future<List<NomikaiPost>> getPosts() async {
    final snap = await DbService.collection('nomikaiPosts').orderBy('date', descending: true).get();

    return snap.docs.map((d) => NomikaiPost.fromMap(d.id, d.data())).toList();
  }

  Future<String> addPost(NomikaiPost post) async {
    final ref = await DbService.collection('nomikaiPosts').add(post.toMap());
    return ref.id;
  }

  Future<void> updatePost(NomikaiPost post) async {
    await DbService.doc('nomikaiPosts/${post.id}').set(post.toMap());
  }

  Future<List<PostComment>> getComments(String postId) async {
    final snap = await DbService.collection('nomikaiPosts/$postId/comments').orderBy('createdAt').get();

    return snap.docs.map((d) => PostComment.fromMap(d.id, d.data())).toList();
  }

  Future<String> addComment(String postId, PostComment c) async {
    final ref = await DbService.collection('nomikaiPosts/$postId/comments').add(c.toMap());
    return ref.id;
  }
}
