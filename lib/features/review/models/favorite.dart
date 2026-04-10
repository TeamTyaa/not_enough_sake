// ============================================================
// お気に入りモデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id;
  final String name;
  final String category;
  final Timestamp createdAt;

  const Favorite({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
  });

  factory Favorite.fromMap(Map<String, dynamic> m) => Favorite(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        category: m['category'] ?? '',
        createdAt: m['createdAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'createdAt': createdAt,
      };
}
