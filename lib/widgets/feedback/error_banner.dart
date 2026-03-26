// ============================================================
// エラーバナー
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../buttons/gold_button.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kRed.withValues(alpha: 0.15),
          border: Border.all(color: kRed.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(children: [
          Expanded(child: Text('⚠ $message', style: const TextStyle(fontSize: 12, color: Color(0xFFc07070)))),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GoldButton(label: '再試行', onPressed: onRetry, small: true, outline: true, danger: true),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: kDim),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ]),
      );
}
