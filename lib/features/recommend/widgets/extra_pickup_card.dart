import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';

class ExtraPickupCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDialog(context),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('＋'),
            const Text('追加ピックアップ'),
            Text('$freeTokens / $paidTokens'),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    String selectedTier = 'low';
    String selectedUse = 'free';

    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => Column(
          children: [
            GoldButton(
              label: '実行',
              onPressed: () async {
                Navigator.pop(context);
                await onPickup(selectedTier, selectedUse);
              },
            )
          ],
        ),
      ),
    );
  }
}
