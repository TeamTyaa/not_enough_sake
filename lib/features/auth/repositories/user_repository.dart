// ============================================================
// ユーザーデータ管理リポジトリ
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/db_service.dart';

import '../models/app_user.dart';
import '../models/blocked_user.dart';

class UserRepository {
  Future<AppUser?> getUser(String uid) async {
    final snap = await DbService.doc('users/$uid').get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()! as Map<String, dynamic>);
  }

  Future<void> setUser(AppUser user) async {
    await DbService.doc('users/${user.uid}').set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteUser(String uid) async {
    // 単一ドキュメントのサブコレクションを削除
    await Future.wait([
      DbService.doc('users/$uid/recs/current').delete(),
      DbService.doc('users/$uid/favorites/list').delete(),
      DbService.doc('users/$uid/tokens').delete(),
    ]);
    // 複数ドキュメントのサブコレクションをバッチ削除
    for (final col in ['reviews', 'recsHistory']) {
      final snap = await DbService.collection('users/$uid/$col').get();
      if (snap.docs.isEmpty) continue;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await DbService.doc('users/$uid').delete();
  }

  Future<bool> isBlacklisted(String uid) async {
    final snap = await DbService.doc('blacklist/$uid').get();
    return snap.exists;
  }

  Future<BlockedUser?> getBlocked(String uid) async {
    final snap = await DbService.doc('blockedUsers/$uid').get();
    if (!snap.exists) return null;
    return BlockedUser.fromMap(uid, snap.data()! as Map<String, dynamic>);
  }

  Future<void> setBlocked(BlockedUser blocked) async {
    await DbService.doc('blockedUsers/${blocked.uid}').set(blocked.toMap());
  }
}
