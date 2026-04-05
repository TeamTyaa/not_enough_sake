import '../../../services/db_service.dart';
import '../models/drink_review.dart';

class ReviewRepository {
  Future<List<DrinkReview>> getReviews(String uid) async {
    final snap = await DbService.collection('users/$uid/reviews').orderBy('date', descending: true).get();

    return snap.docs.map((d) => DrinkReview.fromMap(d.id, d.data())).toList();
  }

  Future<String> addReview(String uid, DrinkReview r) async {
    final ref = await DbService.collection('users/$uid/reviews').add(r.toMap());
    return ref.id;
  }
}
