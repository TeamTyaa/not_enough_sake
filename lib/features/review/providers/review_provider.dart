// ══════════════════════════════════════════════════════════
// レビュープロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mock_db.dart';
import '../models/drink_review.dart';

class ReviewsNotifier extends StateNotifier<List<DrinkReview>> {
  final String uid;
  ReviewsNotifier(this.uid) : super([]) {
    _load();
  }

  void _load() {
    state = MockDb.getReviews(uid);
  }

  Future<void> addReview(DrinkReview r) async {
    final id = await MockDb.addReview(uid, r);
    state = [DrinkReview.fromMap(id, r.toMap()), ...state];
  }
}

final reviewsProvider = StateNotifierProvider.family<ReviewsNotifier, List<DrinkReview>, String>(
  (_, uid) => ReviewsNotifier(uid),
);
