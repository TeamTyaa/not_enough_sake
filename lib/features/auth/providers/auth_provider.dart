// ============================================================
// 認証状態プロバイダ
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../common/models/taste_profile.dart';
import '../models/app_user.dart';
import '../models/blocked_user.dart';
import '../repositories/user_repository.dart';

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
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _restoreSession();
  }

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _userRepository = UserRepository();

  // ── 起動時にセッション復元 ────────────────────────────
  Future<void> _restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    await _onSignedIn(firebaseUser);
  }

  // ── サインイン（Web / モバイル を自動切り替え） ────────
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (kIsWeb) {
        await _signInWithGoogleWeb();
      } else {
        await _signInWithGoogleMobile();
      }
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ログインに失敗しました: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'ログインに失敗しました: $e',
      );
    }
  }

// Web: signInWithPopup を使う
  Future<void> _signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider();
    // 必要に応じてスコープ追加
    // provider.addScope('email');
    final result = await _auth.signInWithPopup(provider);
    await _onSignedIn(result.user!);
  }

  // モバイル: google_sign_in パッケージ経由
  Future<void> _signInWithGoogleMobile() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // キャンセル
      state = state.copyWith(isLoading: false);
      return;
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _onSignedIn(result.user!);
  }

  // ── サインイン後の共通処理 ────────────────────────────
  Future<void> _onSignedIn(User firebaseUser) async {
    final uid = firebaseUser.uid;

    if (await _userRepository.isBlacklisted(uid)) {
      await _auth.signOut();
      if (!kIsWeb) await _googleSignIn.signOut();
      state = state.copyWith(
        isLoading: false,
        error: 'このアカウントはご利用いただけません。',
      );
      return;
    }

    final blocked = await _userRepository.getBlocked(uid);
    if (blocked != null) {
      if (blocked.isUnderAge) {
        state = state.copyWith(isLoading: false, blocked: blocked);
        return;
      }
    }

    final appUser = await _userRepository.getUser(uid) ??
        AppUser(
          uid: uid,
          nickname: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          birthday: Timestamp.now(),
          gender: '',
          genres: const [],
          tasteProfile: const TasteProfile(),
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );

    state = state.copyWith(
      isLoading: false,
      user: appUser,
      clearBlocked: true,
      clearError: true,
    );
  }

  // ── プロフィール保存 ──────────────────────────────────
  Future<void> saveProfile(AppUser user) async {
    await _userRepository.setUser(user);
    state = state.copyWith(user: user);
  }

  Future<void> updateUser(AppUser user) async {
    await _userRepository.setUser(user);
    state = state.copyWith(user: user);
  }

  // ── サインアウト ──────────────────────────────────────
  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
    state = const AuthState();
  }

  // ── アカウント削除 ────────────────────────────────────
  Future<void> deleteAccount(String uid) async {
    await _userRepository.deleteUser(uid);
    await _auth.currentUser?.delete();
    if (!kIsWeb) await _googleSignIn.signOut();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
