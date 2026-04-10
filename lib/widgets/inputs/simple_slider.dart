// ============================================================
// シンプルスライダー
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

// ── SimpleSlider（プロフィール登録用） ────────────────────
class SimpleSlider extends StatelessWidget {
  final TasteAxis axis;
  final int value;
  final ValueChanged<int> onChanged;

  const SimpleSlider({
    super.key,
    required this.axis,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('${axis.emoji} ${axis.simpleLeft}',
                    style: TextStyle(fontSize: 12, color: value < 0 ? kGold : kDim))),
            Expanded(
                child: Text(axis.simpleRight,
                    textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: value > 0 ? kGold : kDim))),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kGold,
              inactiveTrackColor: const Color(0xFF1a1816),
              thumbColor: kGold,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              min: -5,
              max: 5,
              divisions: 10,
              value: value.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('-5', style: TextStyle(fontSize: 8, color: Color(0xFF2a2018))),
              const Text('0', style: TextStyle(fontSize: 8, color: Color(0xFF5a4a38))),
              const Text('+5', style: TextStyle(fontSize: 8, color: Color(0xFF2a2018))),
            ],
          ),
          const SizedBox(height: 16),
        ],
      );
}
