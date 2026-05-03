// ============================================================
// おすすめ生成制御
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../../auth/models/app_user.dart';
import '../../review/models/favorite.dart';
import '../../review/models/review.dart';
import '../../review/providers/favorite_provider.dart';
import '../../review/providers/review_provider.dart';
import '../../review/screens/review_screen.dart';
import '../../token/providers/token_provider.dart';
import '../models/recommended_drink.dart';
import '../providers/recommend_provider.dart';

class RecommendController {
  final WidgetRef ref;
  final AppUser user;

  RecommendController(this.ref, this.user);

  // ── 初回ロード ─────────────────────────
  void initIfNeeded(RecsState recs, List<Review> reviews) {
    if (!recs.isLoading && recs.recs == null && recs.error == null && recs.canFetch) {
      ref.read(recsProvider((user.uid, user.genres)).notifier).fetchRecs(user.tasteProfile, reviews);
    }
  }

  // ── リフレッシュ ───────────────────────
  Future<void> refresh(List<Review> reviews) async {
    final recs = ref.read(recsProvider((user.uid, user.genres)));
    if (!recs.canFetch) return;
    await ref.read(recsProvider((user.uid, user.genres)).notifier).fetchRecs(user.tasteProfile, reviews);
  }

  // ── 通常レビュー ───────────────────────
  void onReview({
    required BuildContext context,
    required RecommendedDrink drink,
    required PriceTier tier,
    required List<Review> reviews,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          drink: drink,
          tierLabel: tier.label,
          uid: user.uid,
          onSaved: (r) => _handleReviewSaved(r, drink, tier.key),
        ),
      ),
    );
  }

  Future<void> _handleReviewSaved(
    Review r,
    RecommendedDrink drink,
    String tierKey,
  ) async {
    final id = await ref.read(reviewsProvider(user.uid).notifier).addReview(r);
    await ref.read(tokenProvider(user.uid).notifier).addFree(1);

    if (r.justRight) {
      final favs = ref.read(favoritesProvider(user.uid));
      if (!favs.any((f) => f.name == drink.name && f.category == drink.category)) {
        await ref.read(favoritesProvider(user.uid).notifier).setFavorites([
          ...favs,
          Favorite(
            id: id,
            name: drink.name,
            category: drink.category,
            createdAt: Timestamp.now(),
          ),
        ]);
      }
    }

    ref.read(recsProvider((user.uid, user.genres)).notifier).markDone(tierKey);

    final updatedReviews = ref.read(reviewsProvider(user.uid));
    final recState = ref.read(recsProvider((user.uid, user.genres)));
    final allDone = kPriceTiers.every((t) => recState.done[t.key] == true);
    if (allDone && recState.canFetch) {
      await ref.read(recsProvider((user.uid, user.genres)).notifier).fetchRecs(user.tasteProfile, updatedReviews);
    }
  }

  // ── 追加レビュー ───────────────────────
  void onExtraReview({
    required BuildContext context,
    required RecommendedDrink drink,
    required String extraKey,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          drink: drink,
          tierLabel: '追加ピックアップ',
          uid: user.uid,
          onSaved: (r) => _handleExtraReviewSaved(r, extraKey),
        ),
      ),
    );
  }

  Future<void> _handleExtraReviewSaved(Review r, String extraKey) async {
    await ref.read(reviewsProvider(user.uid).notifier).addReview(r);
    await ref.read(tokenProvider(user.uid).notifier).addFree(1);
    ref.read(recsProvider((user.uid, user.genres)).notifier).markDone(extraKey);
  }

  // ── ピックアップ ───────────────────────
  Future<void> onPickup(
    String tier,
    String useType,
    List<Review> reviews,
    BuildContext context,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final ok = useType == 'free'
        ? await ref.read(tokenProvider(user.uid).notifier).spendFree(10)
        : await ref.read(tokenProvider(user.uid).notifier).spendPaid(1);

    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('トークンが不足しています')));
      return;
    }

    final success = await ref.read(recsProvider((user.uid, user.genres)).notifier).fetchExtraPickup(
          tier: tier,
          taste: user.tasteProfile,
          history: reviews,
          genres: user.genres,
        );

    // API失敗時はトークンを返金する
    if (!success) {
      if (useType == 'free') {
        await ref.read(tokenProvider(user.uid).notifier).addFree(10);
      } else {
        await ref.read(tokenProvider(user.uid).notifier).addPaid(1);
      }
    }
  }
}
