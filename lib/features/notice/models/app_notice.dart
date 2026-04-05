// ============================================================
// お知らせデータモデル
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotice {
  final String id;
  final String title;
  final String body;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;

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
        startAt: _toDateTime(m['startAt']),
        endAt: _toDateTime(m['endAt']),
        createdAt: _toDateTime(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool isActive(DateTime now) => !now.isBefore(startAt) && !now.isAfter(endAt);

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime(2000);
    if (value is DateTime) return value;
    return DateTime(2000);
  }
}
