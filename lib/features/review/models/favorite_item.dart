// ============================================================
// お気に入りデータモデル
// ============================================================

class FavoriteItem {
  final String id;
  final String name;
  final String category;

  const FavoriteItem({required this.id, required this.name, required this.category});

  factory FavoriteItem.fromMap(Map<String, dynamic> m) => FavoriteItem(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        category: m['category'] ?? '',
      );
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'category': category};
}
