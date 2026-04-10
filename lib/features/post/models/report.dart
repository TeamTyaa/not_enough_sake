// ============================================================
// 通報データモデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String postId;
  final String authorNick;
  final String reporterUid;
  final String reporterNick;
  final String reason;
  final String detail;
  final Timestamp createdAt;

  const Report({
    required this.postId,
    required this.authorNick,
    required this.reporterUid,
    required this.reporterNick,
    required this.reason,
    required this.detail,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'authorNick': authorNick,
        'reporterUid': reporterUid,
        'reporterNick': reporterNick,
        'reason': reason,
        'detail': detail,
        'createdAt': createdAt,
      };
}
