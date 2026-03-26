// ============================================================
// 星評価入力
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

// ── 星評価入力 ────────────────────────────────────────────
class StarInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarInput({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
            5,
            (i) => GestureDetector(
                  onTap: () => onChanged(i + 1),
                  child: Text(i < value ? '★' : '☆',
                      style: TextStyle(
                        fontSize: 28,
                        color: i < value ? kGold : const Color(0xFF2a2420),
                      )),
                )),
      );
}
