import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/main_screen.dart';
import 'features/auth/models/blocked_user.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'firebase_options.dart';
import 'services/mock_db.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MockDb.init();
  runApp(const ProviderScope(child: NotEnoughSakeApp()));
}

class NotEnoughSakeApp extends StatelessWidget {
  const NotEnoughSakeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '酒語りＮ',
        debugShowCheckedModeBanner: false,
        theme: kAppTheme,
        home: const _RootRouter(),
      );
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // 未成年ブロック
    if (auth.blocked != null) return _UnderageScreen(blocked: auth.blocked!);
    // 未ログイン
    if (!auth.isLoading && auth.user == null && auth.error == null) {
      return const LoginScreen();
    }
    // ログイン済みだがプロフィール未登録
    if (auth.user != null && auth.user!.nickname.isEmpty) {
      return ProfileScreen(
        uid: auth.user!.uid,
        displayName: auth.user!.nickname,
        email: auth.user!.email,
      );
    }
    // プロフィール登録済み → メイン
    if (auth.user != null) return const MainScreen();
    // ローディング
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: kGold)),
    );
  }
}

// ── 未成年ブロック画面 ────────────────────────────────────
class _UnderageScreen extends StatelessWidget {
  final BlockedUser blocked;
  const _UnderageScreen({required this.blocked});

  @override
  Widget build(BuildContext context) {
    final birthday = DateTime.tryParse(blocked.birthday);
    int daysLeft = 0;
    if (birthday != null) {
      final turnsAdult = DateTime(birthday.year + 20, birthday.month, birthday.day);
      daysLeft = turnsAdult.difference(DateTime.now()).inDays.clamp(0, 99999);
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔒', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 20),
              const Text(
                'お酒は二十歳になってから。',
                style: TextStyle(fontSize: 22, color: kText, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '胸張って堂々と楽しもう。',
                style: TextStyle(fontSize: 22, color: kGold, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'このアカウントは20歳未満のためご利用いただけません。\n'
                '20歳になるまで、あと ',
                style: const TextStyle(fontSize: 13, color: kMuted, height: 1.85),
                textAlign: TextAlign.center,
              ),
              Text('$daysLeft 日', style: const TextStyle(fontSize: 18, color: kGold)),
              const SizedBox(height: 16),
              const Text(
                '成人になると自動的にご利用いただけるようになります。',
                style: TextStyle(fontSize: 11, color: kDim, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const Text(
                '酒語りＮ',
                style: TextStyle(fontSize: 10, color: Color(0xFF2a2018), letterSpacing: 2),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
