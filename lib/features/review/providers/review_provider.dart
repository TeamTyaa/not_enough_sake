// ══════════════════════════════════════════════════════════
// レビュープロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../repositories/review_repository.dart';

class ReviewsNotifier extends StateNotifier<List<Review>> {
  final String uid;
  ReviewsNotifier(this.uid) : super([]) {
    _load();
  }

  final _reviewRepository = ReviewRepository();

  Future<void> _load() async {
    try {
      state = await _reviewRepository.getReviews(uid);
    } catch (_) {}
  }

  Future<String> addReview(Review r) async {
    final id = await _reviewRepository.addReview(uid, r);
    state = [Review.fromMap(id, r.toMap()), ...state];
    return id;
  }
}

final reviewsProvider = StateNotifierProvider.family<ReviewsNotifier, List<Review>, String>(
  (_, uid) => ReviewsNotifier(uid),
);
