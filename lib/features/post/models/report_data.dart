// ============================================================
// 通報データモデル
// ============================================================

class ReportData {
  final String postId;
  final String authorNick;
  final String reporterUid;
  final String reporterNick;
  final String reason;
  final String detail;
  final String reportedAt;

  const ReportData({
    required this.postId,
    required this.authorNick,
    required this.reporterUid,
    required this.reporterNick,
    required this.reason,
    required this.detail,
    required this.reportedAt,
  });

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'authorNick': authorNick,
        'reporterUid': reporterUid,
        'reporterNick': reporterNick,
        'reason': reason,
        'detail': detail,
        'reportedAt': reportedAt,
      };
}
