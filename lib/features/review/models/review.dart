// ============================================================
// レビューモデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/models/taste_profile.dart';

class Review {
  final String id;
  final String name;
  final String category;
  final String tier; // "low" | "mid" | "high" | "extra"
  final TasteProfile sliders;
  final String text;
  final bool justRight;
  final String? officialUrl;
  final Timestamp createdAt;

  const Review({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    required this.sliders,
    required this.text,
    required this.justRight,
    this.officialUrl,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> m) => Review(
        id: id,
        name: m['name'] ?? '',
        category: m['category'] ?? '',
        tier: m['tier'] ?? '',
        sliders: TasteProfile.fromMap(
          (m['sliders'] as Map<String, dynamic>?) ?? {},
        ),
        text: m['text'] ?? '',
        justRight: m['justRight'] ?? false,
        officialUrl: m['officialUrl'] as String?,
        createdAt: m['createdAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'tier': tier,
        'sliders': sliders.toMap(),
        'text': text,
        'justRight': justRight,
        'officialUrl': officialUrl,
        'createdAt': createdAt,
      };
}
