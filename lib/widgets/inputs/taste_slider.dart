// ============================================================
// 好みスライダー（レビュー用）
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

// ── 好みスライダー（レビュー用） ──────────────────────────
class TasteSlider extends StatelessWidget {
  final TasteAxis axis;
  final int value; // -5 ～ +5
  final ValueChanged<int> onChanged;
  final bool showCenterBadge;

  const TasteSlider({
    super.key,
    required this.axis,
    required this.value,
    required this.onChanged,
    this.showCenterBadge = true,
  });

  bool get _center => value.abs() <= 1;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('${axis.emoji} ${axis.left}',
                    style: TextStyle(fontSize: 11, color: value < -1 ? kGold : kDim))),
            if (showCenterBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: _center ? kGold.withValues(alpha: 0.4) : kBorder),
                  color: _center ? kGold.withValues(alpha: 0.08) : Colors.transparent,
                ),
                child: Text('ちょうどいい',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: _center ? kGold : const Color(0xFF2e2820),
                    )),
              ),
            Expanded(
                child: Text(axis.right,
                    textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: value > 1 ? kGold : kDim))),
          ]),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kGold,
              inactiveTrackColor: const Color(0xFF1a1816),
              thumbColor: _center ? const Color(0xFF7a6040) : kGold,
              overlayColor: kGold.withValues(alpha: 0.1),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
          const SizedBox(height: 12),
        ],
      );
}
