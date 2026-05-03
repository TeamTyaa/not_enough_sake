// ══════════════════════════════════════════════════════════
// お気に入りプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite.dart';
import '../repositories/favorite_repository.dart';

class FavoritesNotifier extends StateNotifier<List<Favorite>> {
  final String uid;
  FavoritesNotifier(this.uid) : super([]) {
    _load();
  }

  final _favoriteRepository = FavoriteRepository();

  Future<void> _load() async {
    try {
      state = await _favoriteRepository.getFavorites(uid);
    } catch (_) {}
  }

  Future<void> setFavorites(List<Favorite> favs) async {
    await _favoriteRepository.setFavorites(uid, favs);
    state = favs;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final original = [...state];
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    try {
      await _favoriteRepository.setFavorites(uid, list);
    } catch (_) {
      state = original;
    }
  }
}

final favoritesProvider = StateNotifierProvider.family<FavoritesNotifier, List<Favorite>, String>(
  (_, uid) => FavoritesNotifier(uid),
);
