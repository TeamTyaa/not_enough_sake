// ============================================================
// カテゴリタグ
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class CategoryTag extends StatelessWidget {
  final String label;
  final Color? color;
  const CategoryTag(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: c.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: c, letterSpacing: 1)),
    );
  }
}
