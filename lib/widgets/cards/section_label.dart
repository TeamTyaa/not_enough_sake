// ============================================================
// セクションラベル
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 3,
              color: kDim,
            )),
      );
}
