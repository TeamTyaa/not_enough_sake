// ══════════════════════════════════════════════════════════
// お気に入りリポジトリ
// ══════════════════════════════════════════════════════════

import '../../../services/db_service.dart';
import '../models/favorite.dart';

class FavoriteRepository {
  Future<List<Favorite>> getFavorites(String uid) async {
    final snap = await DbService.doc('users/$uid/favorites/list').get();
    if (!snap.exists) return [];

    final data = snap.data()! as Map<String, dynamic>;
    return (data['items'] as List? ?? []).map((e) => Favorite.fromMap(e! as Map<String, dynamic>)).toList();
  }

  Future<void> setFavorites(String uid, List<Favorite> items) async {
    await DbService.doc('users/$uid/favorites/list').set({
      'items': items.map((e) => e.toMap()).toList(),
    });
  }
}
