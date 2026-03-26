// ============================================================
// ゴールドボタン
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  final bool outline;
  final bool danger;
  final bool loading;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.small = false,
    this.outline = false,
    this.danger = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = danger ? kRed : kGold;
    final h = small ? 32.0 : 44.0;
    final fs = small ? 10.0 : 11.0;
    final px = small ? 14.0 : 22.0;

    return SizedBox(
      height: h,
      child: outline
          ? OutlinedButton(
              onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: onPressed == null ? kDim : base),
                foregroundColor: onPressed == null ? kDim : base,
                padding: EdgeInsets.symmetric(horizontal: px),
                shape: const RoundedRectangleBorder(),
                textStyle: TextStyle(fontSize: fs, letterSpacing: 2),
              ),
              child: loading
                  ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: base))
                  : Text(label),
            )
          : ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: onPressed == null ? const Color(0xFF1e1c18) : base,
                foregroundColor: onPressed == null ? kDim : kBg,
                padding: EdgeInsets.symmetric(horizontal: px),
                shape: const RoundedRectangleBorder(),
                textStyle: TextStyle(fontSize: fs, letterSpacing: 2),
              ),
              child: loading
                  ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kBg))
                  : Text(label),
            ),
    );
  }
}
