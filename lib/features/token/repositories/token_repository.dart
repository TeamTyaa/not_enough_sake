import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/db_service.dart';
import '../models/token_balance.dart';

class TokenRepository {
  Future<TokenBalance> getTokens(String uid) async {
    final snap = await DbService.doc('users/$uid/tokens').get();
    if (!snap.exists) return const TokenBalance();
    return TokenBalance.fromMap(snap.data()! as Map<String, dynamic>);
  }

  Future<void> setTokens(String uid, TokenBalance t) async {
    await DbService.doc('users/$uid/tokens').set(t.toMap());
  }

  Future<bool> spendFree(String uid, int amount) async {
    final ref = DbService.doc('users/$uid/tokens');

    return await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists ? TokenBalance.fromMap(snap.data()! as Map<String, dynamic>) : const TokenBalance();

      if (current.free < amount) return false;

      final next = current.copyWith(free: current.free - amount);
      tx.set(ref, next.toMap());

      return true;
    });
  }

  Future<bool> spendPaid(String uid, int amount) async {
    final tokens = await getTokens(uid);
    if (tokens.paid < amount) return false;

    final next = tokens.copyWith(paid: tokens.paid - amount);
    await setTokens(uid, next);
    return true;
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
