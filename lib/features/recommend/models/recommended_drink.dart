// ============================================================
// おすすめお酒データモデル
// ============================================================

class RecommendedDrink {
  final String name;
  final String category;
  final String description;
  final String? profile;
  final String? occasion;
  final String? officialUrl;
  final String priceKey; // "low" | "mid" | "high"

  const RecommendedDrink({
    required this.name,
    required this.category,
    required this.description,
    this.profile,
    this.occasion,
    this.officialUrl,
    required this.priceKey,
  });

  factory RecommendedDrink.fromMap(Map<String, dynamic> m, String priceKey) => RecommendedDrink(
        name: m['name'] ?? '',
        category: m['category'] ?? '',
        description: m['description'] ?? '',
        profile: m['profile'] as String?,
        occasion: m['occasion'] as String?,
        officialUrl: m['officialUrl'] as String?,
        priceKey: priceKey,
      );
}
