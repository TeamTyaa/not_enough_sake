import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/main_screen.dart';
import 'features/auth/models/blocked_user.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: NotEnoughSakeApp()));
}

class NotEnoughSakeApp extends StatelessWidget {
  const NotEnoughSakeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '酒語りＮ',
        debugShowCheckedModeBanner: false,
        theme: kAppTheme,
        home: const SplashScreen(),
      );
}

// ── スプラッシュ画面 ──────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    // アニメーション全体の長さ: 0.5 + 1.0 + 0.4 + 0.1 = 2.0秒
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // フェードイン: 0.0 → 0.25（0〜500ms）
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // フェードアウト: 0.75 → 0.95（1500〜1900ms）
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.75, 0.95, curve: Curves.easeOut),
      ),
    );

    // バックグラウンド処理とアニメーションを並行して実行
    _runSplash();
  }

  Future<void> _runSplash() async {
    // アニメーションとバックグラウンド処理を並行実行
    await Future.wait([
      _ctrl.forward(), // アニメーション（2.0秒）
      _preload(), // バックグラウンド処理
    ]);

    // 0.1秒の真っ暗画面（アニメーション終了後）
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const _RootRouter(),
          transitionDuration: Duration.zero, // 即切り替え
        ),
      );
    }
  }

  // バックグラウンドで行う処理
  Future<void> _preload() async {
    // Firebase Auth のセッション復元待ち・その他初期化が必要なら追加
    await Future.delayed(const Duration(milliseconds: 100)); // 最低待機
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              // フェードイン中は _fadeIn、フェードアウト中は _fadeOut を使う
              final opacity = _ctrl.value < 0.75 ? _fadeIn.value : _fadeOut.value;
              return Opacity(
                opacity: opacity,
                child: Image.asset(
                  'assets/sake.png',
                  width: 160,
                  height: 160,
                ),
              );
            },
          ),
        ),
      );
}

// ── ルーティング ──────────────────────────────────────────
class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kGold)),
      );
    }
    if (auth.blocked != null) return _UnderageScreen(blocked: auth.blocked!);
    if (auth.user == null) return const LoginScreen();
    if (auth.user!.nickname.isEmpty) {
      return ProfileScreen(
        uid: auth.user!.uid,
        displayName: auth.user!.nickname,
        email: auth.user!.email,
      );
    }
    return const MainScreen();
  }
}

// ── 未成年ブロック画面（変更なし） ───────────────────────
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
                'このアカウントは20歳未満のためご利用いただけません。\n20歳になるまで、あと ',
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
