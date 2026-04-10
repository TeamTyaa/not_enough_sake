// ============================================================
// お知らせデータモデル
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotice {
  final String id;
  final String title;
  final String body;
  final Timestamp startAt;
  final Timestamp endAt;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotice.fromMap(String id, Map<String, dynamic> m) => AppNotice(
        id: id,
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        startAt: m['startAt'] ?? Timestamp.now(),
        endAt: m['endAt'] ?? Timestamp.now(),
        createdAt: m['createdAt'] ?? Timestamp.now(),
        updatedAt: m['updatedAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'startAt': startAt,
        'endAt': endAt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  bool get isActive {
    final now = Timestamp.now();
    return startAt.compareTo(now) <= 0 && endAt.compareTo(now) > 0;
  }
}
