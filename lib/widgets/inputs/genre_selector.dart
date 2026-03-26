// ============================================================
// ジャンル選択
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class GenreSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const GenreSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kGenres.map((g) {
          final on = selected.contains(g);
          return GestureDetector(
            onTap: () => onChanged(
              on ? selected.where((x) => x != g).toList() : [...selected, g],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: on ? kGold : const Color(0xFF2a2420)),
                color: on ? kGold.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text('${on ? "✓ " : ""}$g', style: TextStyle(fontSize: 11, color: on ? kGold : kDim)),
            ),
          );
        }).toList(),
      );
}
