// ══════════════════════════════════════════════════════════
// お気に入りプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_item.dart';
import '../repositories/favorite_repository.dart';

class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  final String uid;
  FavoritesNotifier(this.uid) : super([]) {
    _load();
  }

  final _favoriteRepository = FavoriteRepository();

  void _load() {
    Future(() async {
      try {
        state = await _favoriteRepository.getFavorites(uid);
      } catch (e) {
        // TODO: エラーハンドリング
      }
    });
  }

  Future<void> setFavorites(List<FavoriteItem> favs) async {
    await _favoriteRepository.setFavorites(uid, favs);
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
