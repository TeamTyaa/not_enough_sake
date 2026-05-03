// ============================================================
// おすすめドリンクモデル
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

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'description': description,
        if (profile != null) 'profile': profile,
        if (occasion != null) 'occasion': occasion,
        if (officialUrl != null) 'officialUrl': officialUrl,
        'priceKey': priceKey,
      };
}

// ============================================================
// おすすめドリンク３本セットモデル
// ============================================================

class RecommendedDrinks {
  final RecommendedDrink low;
  final RecommendedDrink mid;
  final RecommendedDrink high;

  const RecommendedDrinks({
    required this.low,
    required this.mid,
    required this.high,
  });

  factory RecommendedDrinks.fromMap(Map<String, dynamic> m) => RecommendedDrinks(
        low: RecommendedDrink.fromMap(m['low'] as Map<String, dynamic>, 'low'),
        mid: RecommendedDrink.fromMap(m['mid'] as Map<String, dynamic>, 'mid'),
        high: RecommendedDrink.fromMap(m['high'] as Map<String, dynamic>, 'high'),
      );

  Map<String, dynamic> toMap() => {
        'low': low.toMap(),
        'mid': mid.toMap(),
        'high': high.toMap(),
      };

  RecommendedDrink? operator [](String key) => switch (key) {
        'low' => low,
        'mid' => mid,
        'high' => high,
        _ => null,
      };

  List<RecommendedDrink> get all => [low, mid, high];
}
