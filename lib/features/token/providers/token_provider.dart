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

  void _load() {
    Future(() async {
      try {
        state = await _tokenRepository.getTokens(uid);
      } catch (e) {
        // TODO: エラーハンドリング
      }
    });
  }

  Future<void> addFree(int amount) async {
    final next = state.copyWith(free: state.free + amount);
    await _tokenRepository.setTokens(uid, next);
    state = next;
  }

  Future<bool> spendFree(int amount) async {
    if (state.free < amount) return false;
    final next = state.copyWith(free: state.free - amount);
    await _tokenRepository.setTokens(uid, next);
    state = next;
    return true;
  }

  Future<bool> spendPaid(int amount) async {
    if (state.paid < amount) return false;
    final next = state.copyWith(paid: state.paid - amount);
    await _tokenRepository.setTokens(uid, next);
    state = next;
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
