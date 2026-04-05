// ══════════════════════════════════════════════════════════
// レビュープロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drink_review.dart';
import '../repositories/review_repository.dart';

class ReviewsNotifier extends StateNotifier<List<DrinkReview>> {
  final String uid;
  ReviewsNotifier(this.uid) : super([]) {
    _load();
  }

  final _reviewRepository = ReviewRepository();

  void _load() {
    Future(() async {
      try {
        state = await _reviewRepository.getReviews(uid);
      } catch (e) {
        // TODO: エラーハンドリング
      }
    });
  }

  Future<void> addReview(DrinkReview r) async {
    final id = await _reviewRepository.addReview(uid, r);
    state = [DrinkReview.fromMap(id, r.toMap()), ...state];
  }
}

final reviewsProvider = StateNotifierProvider.family<ReviewsNotifier, List<DrinkReview>, String>(
  (_, uid) => ReviewsNotifier(uid),
);
