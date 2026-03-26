// ============================================================
// お酒レビューデータモデル
// ============================================================

import '../../common/models/taste_profile.dart';

class DrinkReview {
  final String id;
  final String name;
  final String category;
  final String tier; // "low" | "mid" | "high" | "extra"
  final TasteProfile sliders;
  final String text;
  final bool justRight;
  final String date; // "YYYY/MM/DD"
  final String? officialUrl;

  const DrinkReview({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    required this.sliders,
    required this.text,
    required this.justRight,
    required this.date,
    this.officialUrl,
  });

  factory DrinkReview.fromMap(String id, Map<String, dynamic> m) => DrinkReview(
        id: id,
        name: m['name'] ?? '',
        category: m['category'] ?? '',
        tier: m['tier'] ?? '',
        sliders: TasteProfile.fromMap(
          (m['sliders'] as Map<String, dynamic>?) ?? {},
        ),
        text: m['text'] ?? '',
        justRight: m['justRight'] ?? false,
        date: m['date'] ?? '',
        officialUrl: m['officialUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'tier': tier,
        'sliders': sliders.toMap(),
        'text': text,
        'justRight': justRight,
        'date': date,
        'officialUrl': officialUrl,
      };
}
