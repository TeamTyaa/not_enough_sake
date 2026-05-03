// ══════════════════════════════════════════════════════════
// トークンプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/token.dart';
import '../repositories/token_repository.dart';

class TokenNotifier extends StateNotifier<Token> {
  final String uid;
  TokenNotifier(this.uid)
      : super(Token(
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        )) {
    _load();
  }

  final _tokenRepository = TokenRepository();

  Future<void> _load() async {
    try {
      state = await _tokenRepository.getTokens(uid);
    } catch (_) {
      // 取得失敗時は初期値（free:0, paid:0）のまま継続
    }
  }

  Future<void> addFree(int amount) async {
    final next = state.copyWith(free: state.free + amount);
    await _tokenRepository.setTokens(uid, next);
    state = next;
  }

  Future<bool> spendFree(int amount) async {
    // トランザクションで競合防止（TokenRepository.spendFree を使用）
    final ok = await _tokenRepository.spendFree(uid, amount);
    if (!ok) return false;
    state = state.copyWith(free: state.free - amount);
    return true;
  }

  Future<bool> spendPaid(int amount) async {
    // トランザクションで競合防止（TokenRepository.spendPaid を使用）
    final ok = await _tokenRepository.spendPaid(uid, amount);
    if (!ok) return false;
    state = state.copyWith(paid: state.paid - amount);
    return true;
  }

  Future<void> addPaid(int amount) async {
    final next = state.copyWith(paid: state.paid + amount);
    await _tokenRepository.setTokens(uid, next);
    state = next;
  }
}

final tokenProvider = StateNotifierProvider.family<TokenNotifier, Token, String>(
  (_, uid) => TokenNotifier(uid),
);
