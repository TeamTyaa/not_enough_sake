// ============================================================
// トークンデータモデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Token {
  final int free; // 合
  final int paid; // 升
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const Token({
    this.free = 0,
    this.paid = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Token.fromMap(Map<String, dynamic> m) => Token(
        free: (m['free'] ?? 0) as int,
        paid: (m['paid'] ?? 0) as int,
        createdAt: m['createdAt'] ?? Timestamp.now(),
        updatedAt: m['updatedAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'free': free,
        'paid': paid,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Token copyWith({
    int? free,
    int? paid,
  }) =>
      Token(
        free: free ?? this.free,
        paid: paid ?? this.paid,
        createdAt: createdAt,
        updatedAt: Timestamp.now(),
      );
}
