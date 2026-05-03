// ══════════════════════════════════════════════════════════
// 追加おすすめカード
// ══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';

class ExtraPickupCard extends StatefulWidget {
  final int freeTokens;
  final int paidTokens;
  final Future<void> Function(String tier, String useType) onPickup;

  const ExtraPickupCard({
    super.key,
    required this.freeTokens,
    required this.paidTokens,
    required this.onPickup,
  });

  @override
  State<ExtraPickupCard> createState() => _ExtraPickupCardState();
}

class _ExtraPickupCardState extends State<ExtraPickupCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : () => _showDialog(context),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          border: Border.all(color: _loading ? kBorder : kGold.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: kGold, strokeWidth: 2),
              )
            else
              const Text('＋', style: TextStyle(fontSize: 24, color: kGold)),
            const SizedBox(height: 8),
            const Text('追加ピックアップ',
                style: TextStyle(fontSize: 11, color: kMuted, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🍶 ${widget.freeTokens}合',
                  style: const TextStyle(fontSize: 10, color: kDim)),
              const Text('  /  ', style: TextStyle(fontSize: 10, color: kBorder)),
              Text('升 ${widget.paidTokens}升',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFc07a5a))),
            ]),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    String selectedTier = kPriceTiers.first.key;
    String selectedUse = widget.freeTokens >= 10 ? 'free' : 'paid';

    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('追加ピックアップ',
                  style: TextStyle(fontSize: 15, color: kText, letterSpacing: 1)),
              const SizedBox(height: 16),

              // 価格帯選択
              const Text('価格帯', style: TextStyle(fontSize: 11, color: kDim)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: kPriceTiers
                    .map((tier) => GestureDetector(
                          onTap: () => setS(() => selectedTier = tier.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: selectedTier == tier.key
                                      ? kGold
                                      : kBorder),
                              color: selectedTier == tier.key
                                  ? kGold.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Text(tier.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: selectedTier == tier.key
                                        ? kGold
                                        : kMuted)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // トークン種別選択
              const Text('使用トークン', style: TextStyle(fontSize: 11, color: kDim)),
              const SizedBox(height: 8),
              Row(children: [
                _UseTypeChip(
                  label: '🍶 10合（無料）',
                  selected: selectedUse == 'free',
                  enabled: widget.freeTokens >= 10,
                  onTap: widget.freeTokens >= 10
                      ? () => setS(() => selectedUse = 'free')
                      : null,
                ),
                const SizedBox(width: 8),
                _UseTypeChip(
                  label: '升 1升（有料）',
                  selected: selectedUse == 'paid',
                  enabled: widget.paidTokens >= 1,
                  onTap: widget.paidTokens >= 1
                      ? () => setS(() => selectedUse = 'paid')
                      : null,
                ),
              ]),
              const SizedBox(height: 20),

              GoldButton(
                label: '実行',
                onPressed: (selectedUse == 'free' && widget.freeTokens >= 10) ||
                        (selectedUse == 'paid' && widget.paidTokens >= 1)
                    ? () async {
                        Navigator.pop(context);
                        setState(() => _loading = true);
                        try {
                          await widget.onPickup(selectedTier, selectedUse);
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UseTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _UseTypeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? kGold
                  : enabled
                      ? kBorder
                      : const Color(0xFF1a1a1a),
            ),
            color: selected ? kGold.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? kGold
                  : enabled
                      ? kMuted
                      : const Color(0xFF3a3028),
            ),
          ),
        ),
      );
}
