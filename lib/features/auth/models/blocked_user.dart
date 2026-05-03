// ============================================================
// 利用制限ユーザーモデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUser {
  final String uid;
  final bool isUnderAge;
  final bool isBanned;
  final String? reason;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const BlockedUser({
    required this.uid,
    required this.isUnderAge,
    required this.isBanned,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlockedUser.fromMap(String uid, Map<String, dynamic> m) => BlockedUser(
        uid: uid,
        isUnderAge: m['isUnderAge'] ?? false,
        isBanned: m['isBanned'] ?? false,
        reason: m['reason'] ?? '',
        createdAt: m['createdAt'] ?? Timestamp.now(),
        updatedAt: m['updatedAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'isUnderAge': isUnderAge,
        'isBanned': isBanned,
        'reason': reason,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  BlockedUser copyWith({
    bool? isUnderAge,
    bool? isBanned,
    String? reason,
  }) =>
      BlockedUser(
        uid: uid,
        isUnderAge: isUnderAge ?? this.isUnderAge,
        isBanned: isBanned ?? this.isBanned,
        reason: reason ?? this.reason,
        createdAt: createdAt,
        updatedAt: Timestamp.now(),
      );
}
