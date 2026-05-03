// ══════════════════════════════════════════════════════════
// トークンリポジトリ
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/db_service.dart';
import '../models/token.dart';

class TokenRepository {
  Future<Token> getTokens(String uid) async {
    final snap = await DbService.doc('users/$uid/tokens').get();
    Token token;
    if (!snap.exists) {
      token = Token(
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
    } else {
      token = Token.fromMap(snap.data()! as Map<String, dynamic>);
    }
    return token;
  }

  Future<void> setTokens(String uid, Token t) async {
    await DbService.doc('users/$uid/tokens').set(t.toMap());
  }

  Future<bool> spendFree(String uid, int amount) async {
    final ref = DbService.doc('users/$uid/tokens');

    return await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists
          ? Token.fromMap(snap.data()! as Map<String, dynamic>)
          : Token(
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
            );

      if (current.free < amount) return false;

      final next = current.copyWith(free: current.free - amount);
      tx.set(ref, next.toMap());

      return true;
    });
  }

  Future<bool> spendPaid(String uid, int amount) async {
    final ref = DbService.doc('users/$uid/tokens');

    return await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists
          ? Token.fromMap(snap.data()! as Map<String, dynamic>)
          : Token(
              createdAt: Timestamp.now(),
              updatedAt: Timestamp.now(),
            );

      if (current.paid < amount) return false;

      final next = current.copyWith(paid: current.paid - amount);
      tx.set(ref, next.toMap());

      return true;
    });
  }

  Future<void> addFree(String uid, int amount) async {
    final tokens = await getTokens(uid);
    final next = tokens.copyWith(free: tokens.free + amount);
    await setTokens(uid, next);
  }

  Future<void> addPaid(String uid, int amount) async {
    final tokens = await getTokens(uid);
    final next = tokens.copyWith(paid: tokens.paid + amount);
    await setTokens(uid, next);
  }
}
