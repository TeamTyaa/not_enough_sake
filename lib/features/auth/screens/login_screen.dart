// ============================================================
// ログイン画面
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🍶', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              RichText(
                  text: const TextSpan(
                style: TextStyle(fontSize: 30, letterSpacing: 2, color: kText),
                children: [
                  TextSpan(text: '酒語りＮ'),
                ],
              )),
              const SizedBox(height: 48),
              const Text(
                'AIがあなた好みの一杯を探します。\nGoogleアカウントでログインしてください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kMuted, height: 1.85),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: kRed.withValues(alpha: 0.15),
                    border: Border.all(color: kRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(auth.error!, style: const TextStyle(fontSize: 12, color: Color(0xFFc07070))),
                ),
              ],
              const SizedBox(height: 36),
              _GoogleSignInButton(
                loading: auth.isLoading,
                onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
              ),
              const SizedBox(height: 52),
              const Text('酒が足りん、まだ見ぬ一杯がある', style: TextStyle(fontSize: 10, color: Color(0xFF2a2018), letterSpacing: 2)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        elevation: 4,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                )
              else
                _GoogleLogo(),
              const SizedBox(width: 12),
              Text(
                loading ? 'ログイン中...' : 'Googleでログイン',
                style: const TextStyle(
                  color: Color(0xFF1a1510),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
        ),
      );
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _GoogleLogoPainter()),
      );
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    void arc(Color c, double start, double sweep) {
      final paint = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.4;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.8),
        start,
        sweep,
        false,
        paint,
      );
    }

    arc(const Color(0xFFEA4335), -0.5, 1.6);
    arc(const Color(0xFF34A853), 1.1, 1.6);
    arc(const Color(0xFFFBBC05), 2.7, 1.6);
    arc(const Color(0xFF4285F4), 4.3, 1.6);

    // Horizontal bar for G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = r * 0.4;
    canvas.drawLine(
      Offset(r, r),
      Offset(size.width * 0.95, r),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
