// ══════════════════════════════════════════════════════════
// 投稿プロバイダー
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../models/nomikai_post.dart';
import '../repositories/post_repository.dart';

class PostsState {
  final List<NomikaiPost> posts;
  final DocumentSnapshot? lastDoc; // カーソル
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PostsState({
    this.posts = const [],
    this.lastDoc,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PostsState copyWith({
    List<NomikaiPost>? posts,
    DocumentSnapshot? lastDoc,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) =>
      PostsState(
        posts: posts ?? this.posts,
        lastDoc: lastDoc ?? this.lastDoc,
        hasMore: hasMore ?? this.hasMore,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : error ?? this.error,
      );
}

class PostsNotifier extends StateNotifier<PostsState> {
  PostsNotifier() : super(const PostsState()) {
    loadFirst();
  }

  final _repo = PostRepository();

  // ── 初回取得・リフレッシュ ────────────────────────────
  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.getFirstPage(kPageSize);
      state = PostsState(
        posts: page.posts,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '投稿の取得に失敗しました: $e',
      );
    }
  }

  // ── 追加取得（無限スクロール） ────────────────────────
  Future<void> loadMore() async {
    // 取得中・これ以上なし・カーソルなし のときは何もしない
    if (state.isLoadingMore || !state.hasMore || state.lastDoc == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.getNextPage(
        lastDoc: state.lastDoc!,
        pageSize: kPageSize,
      );
      state = state.copyWith(
        posts: [...state.posts, ...page.posts],
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: '追加取得に失敗しました: $e',
      );
    }
  }

  // ── 投稿追加 ──────────────────────────────────────────
  Future<void> addPost(NomikaiPost post) async {
    final id = await _repo.addPost(post);
    // 先頭に追加（最新順）
    state = state.copyWith(
      posts: [post.copyWith(id: id), ...state.posts],
    );
  }

  // ── 投稿更新（Firestore + ローカル） ─────────────────
  Future<void> updatePost(NomikaiPost post) async {
    await _repo.updatePost(post);
    state = state.copyWith(
      posts: state.posts.map((p) => p.id == post.id ? post : p).toList(),
    );
  }

  // ── ローカル状態のみ更新（Firestore への書き込みなし） ─
  // intent / rating 操作はリポジトリ側で書き込み済みのため、
  // 画面の楽観的更新にはこちらを使うこと（二重書き込み防止）
  void patchLocal(NomikaiPost post) {
    state = state.copyWith(
      posts: state.posts.map((p) => p.id == post.id ? post : p).toList(),
    );
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>(
  (_) => PostsNotifier(),
);
