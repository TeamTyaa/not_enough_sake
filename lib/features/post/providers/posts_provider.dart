// ══════════════════════════════════════════════════════════
// 飲み会掲示板プロバイダー
// ══════════════════════════════════════════════════════════
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mock_db.dart';
import '../models/nomikai_post.dart';

class PostsNotifier extends StateNotifier<List<NomikaiPost>> {
  PostsNotifier() : super([]) {
    _load();
  }

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
