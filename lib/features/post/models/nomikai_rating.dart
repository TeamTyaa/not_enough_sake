// ============================================================
// 飲み会評価モデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class NomikaiRating {
  final String postId;
  final String fromNick;
  final String fromUid;
  final String toNick;
  final String toUid;
  final String role; // "host" | "guest"
  final int stars;
  final String comment;
  final Timestamp createdAt;

  const NomikaiRating({
    required this.postId,
    required this.fromNick,
    required this.fromUid,
    required this.toNick,
    required this.toUid,
    required this.role,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  factory NomikaiRating.fromMap(Map<String, dynamic> m) => NomikaiRating(
        postId: m['postId'] ?? '',
        fromNick: m['fromNick'] ?? '',
        fromUid: m['fromUid'] ?? '',
        toNick: m['toNick'] ?? '',
        toUid: m['toUid'] ?? '',
        role: m['role'] ?? 'guest',
        stars: (m['stars'] ?? 0) as int,
        comment: m['comment'] ?? '',
        createdAt: m['createdAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'fromNick': fromNick,
        'fromUid': fromUid,
        'toNick': toNick,
        'toUid': toUid,
        'role': role,
        'stars': stars,
        'comment': comment,
        'createdAt': createdAt,
      };
}
