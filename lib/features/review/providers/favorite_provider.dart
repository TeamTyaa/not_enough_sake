// ══════════════════════════════════════════════════════════
// お気に入りプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mock_db.dart';
import '../models/favorite_item.dart';

class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  final String uid;
  FavoritesNotifier(this.uid) : super([]) {
    _load();
  }

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
