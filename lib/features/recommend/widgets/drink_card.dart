import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';
import '../../../widgets/cards/category_tag.dart';
import '../../../widgets/media/drink_image.dart';
import '../models/recommended_drink.dart';

class DrinkCard extends StatelessWidget {
  final RecommendedDrink drink;
  final PriceTier tier;
  final bool reviewed;
  final bool isExtra;
  final VoidCallback onReview;

  const DrinkCard({
    super.key,
    required this.drink,
    required this.tier,
    required this.reviewed,
    this.isExtra = false,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: reviewed ? kGold.withValues(alpha: 0.04) : kCard,
        border: Border.all(
          color: isExtra
              ? kGold.withValues(alpha: 0.2)
              : reviewed
                  ? kGold.withValues(alpha: 0.3)
                  : kBorder,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 画像
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            child: DrinkImage(
              name: drink.name,
              category: drink.category,
              height: 130,
            ),
          ),

          // 価格帯
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF0a0806),
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(tier.badge, style: TextStyle(fontSize: 10, color: tier.color)),
                  const SizedBox(width: 6),
                  Text(tier.label, style: const TextStyle(fontSize: 10, color: kDim)),
                  if (isExtra) const Text(' ✦追加', style: TextStyle(fontSize: 10, color: kGold)),
                ]),
                if (reviewed) const Text('✓ 済み', style: TextStyle(fontSize: 9, color: kGreen)),
              ],
            ),
          ),

          // 本文
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryTag(drink.category),
                  const SizedBox(height: 8),
                  Text(drink.name, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Text(drink.description, style: const TextStyle(fontSize: 12)),
                  ),
                  if (drink.profile != null) Text('🍷 ${drink.profile}', style: const TextStyle(fontSize: 11)),
                  if (drink.occasion != null) Text('✦ ${drink.occasion}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 8),
                  if (!reviewed)
                    GoldButton(
                      label: '飲んだ！レビュー →',
                      small: true,
                      onPressed: onReview,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
