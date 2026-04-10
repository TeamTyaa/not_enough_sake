// ══════════════════════════════════════════════════════════
// レビューリポジトリ
// ══════════════════════════════════════════════════════════

import '../../../services/db_service.dart';
import '../models/review.dart';

class ReviewRepository {
  Future<List<Review>> getReviews(String uid) async {
    final snap = await DbService.collection('users/$uid/reviews').orderBy('createdAt', descending: true).get();

    return snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
  }

  Future<String> addReview(String uid, Review r) async {
    final ref = await DbService.collection('users/$uid/reviews').add(r.toMap());
    return ref.id;
  }
}
