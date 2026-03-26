// ============================================================
// 認証プロバイダー
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mock_db.dart';
import '../models/app_user.dart';
import '../models/blocked_user.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final BlockedUser? blocked;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.blocked,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    BlockedUser? blocked,
    bool clearUser = false,
    bool clearError = false,
    bool clearBlocked = false,
  }) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        blocked: clearBlocked ? null : blocked ?? this.blocked,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // TODO: Firebase実装時 → Firebase Auth に差し替え
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // モック: 固定ユーザー
      const mockUid = 'mock_uid_123';

      // ブラックリストチェック
      if (MockDb.isBlacklisted(mockUid)) {
        state = state.copyWith(
          isLoading: false,
          error: 'このアカウントはご利用いただけません。',
        );
        return;
      }

      // 未成年ブロックチェック
      final blocked = MockDb.getBlocked(mockUid);
      if (blocked != null) {
        final birthday = DateTime.tryParse(blocked.birthday);
        if (birthday != null) {
          final turnsAdult = DateTime(birthday.year + 20, birthday.month, birthday.day);
          if (DateTime.now().isBefore(turnsAdult)) {
            state = state.copyWith(isLoading: false, blocked: blocked);
            return;
          }
        }
      }

      // プロフィール取得
      final user = MockDb.getUser(mockUid);
      state = state.copyWith(isLoading: false, user: user, clearBlocked: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ログインに失敗しました: $e',
      );
    }
  }

  Future<void> saveProfile(AppUser user) async {
    await MockDb.setUser(user);
    state = state.copyWith(user: user);
  }

  Future<void> updateUser(AppUser user) async {
    await MockDb.setUser(user);
    state = state.copyWith(user: user);
  }

  Future<void> signOut() async {
    state = const AuthState();
  }

  Future<void> deleteAccount(String uid) async {
    await MockDb.deleteUserData(uid);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
