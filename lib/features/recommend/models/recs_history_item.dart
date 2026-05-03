// ============================================================
// おすすめ履歴アイテム
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import 'recommended_drink.dart';

class RecsHistoryItem {
  final String id;
  final RecommendedDrinks recs;
  final DateTime fetchedAt;

  const RecsHistoryItem({
    required this.id,
    required this.recs,
    required this.fetchedAt,
  });

  factory RecsHistoryItem.fromMap(String id, Map<String, dynamic> m) => RecsHistoryItem(
        id: id,
        recs: RecommendedDrinks.fromMap(m['recs'] as Map<String, dynamic>),
        fetchedAt: (m['fetchedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'recs': recs.toMap(),
        'fetchedAt': Timestamp.fromDate(fetchedAt),
      };
}
