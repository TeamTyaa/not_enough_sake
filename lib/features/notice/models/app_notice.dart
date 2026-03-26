// ============================================================
// お知らせデータモデル
// ============================================================

class AppNotice {
  final String id;
  final String title;
  final String body;
  final String startAt; // "YYYY-MM-DD"
  final String endAt; // "YYYY-MM-DD"
  final String createdAt;

  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
  });

  factory AppNotice.fromMap(String id, Map<String, dynamic> m) => AppNotice(
        id: id,
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        startAt: m['startAt'] ?? '',
        endAt: m['endAt'] ?? '',
        createdAt: m['createdAt'] ?? '',
      );

  bool isActive(DateTime today) {
    final s = DateTime.tryParse(startAt);
    final e = DateTime.tryParse(endAt);
    if (s == null || e == null) return false;
    return !today.isBefore(s) && !today.isAfter(e);
  }
}
