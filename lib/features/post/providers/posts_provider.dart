// ══════════════════════════════════════════════════════════
// 飲み会掲示板プロバイダー
// ══════════════════════════════════════════════════════════
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nomikai_post.dart';
import '../repositories/post_repository.dart';

class PostsNotifier extends StateNotifier<List<NomikaiPost>> {
  PostsNotifier() : super([]) {
    _load();
  }

  final _postRepository = PostRepository();

  void _load() {
    Future(() async {
      try {
        state = await _postRepository.getPosts();
      } catch (e) {
        // TODO: エラーハンドリング
      }
    });
  }

  Future<void> addPost(NomikaiPost post) async {
    final id = await _postRepository.addPost(post);
    state = [NomikaiPost.fromMap(id, post.toMap()), ...state];
  }

  Future<void> updatePost(NomikaiPost post) async {
    await _postRepository.updatePost(post);
    state = state.map((p) => p.id == post.id ? post : p).toList();
  }

  NomikaiPost? findById(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, List<NomikaiPost>>(
  (_) => PostsNotifier(),
);
