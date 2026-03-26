// ============================================================
// 信頼バッジ
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class TrustBadge extends StatelessWidget {
  final double? score;
  final int count;
  const TrustBadge({super.key, this.score, required this.count});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return const Text('評価なし', style: TextStyle(fontSize: 10, color: kDim));
    }
    final stars = score!.round().clamp(0, 5);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('★' * stars + '☆' * (5 - stars), style: const TextStyle(fontSize: 11, color: kGold)),
      const SizedBox(width: 4),
      Text('($count件)', style: const TextStyle(fontSize: 9, color: kDim)),
    ]);
  }
}
