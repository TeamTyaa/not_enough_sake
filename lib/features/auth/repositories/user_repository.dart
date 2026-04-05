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
}
