// ============================================================
// オフラインバナー
// ============================================================

import 'package:flutter/material.dart';

// ── オフラインバナー ──────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  final bool offline;
  const OfflineBanner({super.key, required this.offline});

  @override
  Widget build(BuildContext context) {
    if (!offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0x33644B14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        'オフラインです。接続が回復すると自動的に同期されます。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Color(0xFFb09040), letterSpacing: 1),
      ),
    );
  }
}
