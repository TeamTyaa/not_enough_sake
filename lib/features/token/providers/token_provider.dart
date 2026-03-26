// ══════════════════════════════════════════════════════════
// トークンプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mock_db.dart';
import '../models/token_balance.dart';

class TokenNotifier extends StateNotifier<TokenBalance> {
  final String uid;
  TokenNotifier(this.uid) : super(const TokenBalance()) {
    _load();
  }

  void _load() {
    state = MockDb.getTokens(uid);
  }

  Future<void> addFree(int amount) async {
    final next = state.copyWith(free: state.free + amount);
    await MockDb.setTokens(uid, next);
    state = next;
  }

  Future<bool> spendFree(int amount) async {
    if (state.free < amount) return false;
    final next = state.copyWith(free: state.free - amount);
    await MockDb.setTokens(uid, next);
    state = next;
    return true;
  }

  Future<bool> spendPaid(int amount) async {
    if (state.paid < amount) return false;
    final next = state.copyWith(paid: state.paid - amount);
    await MockDb.setTokens(uid, next);
    state = next;
    return true;
  }

  Future<void> addPaid(int amount) async {
    final next = state.copyWith(paid: state.paid + amount);
    await MockDb.setTokens(uid, next);
    state = next;
  }
}

final tokenProvider = StateNotifierProvider.family<TokenNotifier, TokenBalance, String>(
  (_, uid) => TokenNotifier(uid),
);
