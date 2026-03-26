import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../../../widgets/feedback/error_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../review/providers/review_provider.dart';
import '../../token/providers/token_provider.dart';
import '../controllers/recommend_controller.dart';
import '../models/recommended_drink.dart';
import '../providers/recommend_provider.dart';
import '../widgets/drink_card.dart';
import '../widgets/extra_pickup_card.dart';

class RecommendScreen extends ConsumerWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final reviews = ref.watch(reviewsProvider(user.uid));
    final recs = ref.watch(recsProvider((user.uid, user.genres)));
    final tokens = ref.watch(tokenProvider(user.uid));

    final controller = RecommendController(ref, user);

    // 初回フェッチ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initIfNeeded(recs, reviews);
    });

    return RefreshIndicator(
      color: kGold,
      backgroundColor: kCard,
      onRefresh: () => controller.refresh(reviews),
      child: CustomScrollView(
        slivers: [
          // ── ヘッダー ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (recs.error != null)
                  ErrorBanner(
                    message: recs.error!,
                    onRetry: () => controller.refresh(reviews),
                  ),
                const Text(
                  '価格帯ごとに1本ずつ。レビューするごとに1合トークンがもらえます。',
                  style: TextStyle(fontSize: 12, color: kDim, height: 1.7),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          // ── カード一覧 ─────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 460,
              child: recs.isLoading
                  ? const _LoadingView()
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // 通常3本
                        ...kPriceTiers.map((tier) {
                          final drinkMap = recs.recs?[tier.key];
                          if (drinkMap == null) return const SizedBox.shrink();

                          final drink = RecommendedDrink.fromMap(drinkMap, tier.key);
                          final reviewed = recs.done[tier.key] ?? false;

                          return DrinkCard(
                            drink: drink,
                            tier: tier,
                            reviewed: reviewed,
                            onReview: () => controller.onReview(
                              context: context,
                              drink: drink,
                              tier: tier,
                              reviews: reviews,
                            ),
                          );
                        }),

                        // 追加ピックアップ
                        ...recs.extraRecs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final extra = entry.value;
                          final extraKey = 'extra_$idx';

                          final drink = RecommendedDrink.fromMap(
                            extra,
                            extra['priceKey'] ?? 'mid',
                          );

                          final reviewed = recs.done[extraKey] ?? false;

                          return DrinkCard(
                            drink: drink,
                            tier: kPriceTiers.firstWhere(
                              (t) => t.key == drink.priceKey,
                              orElse: () => kPriceTiers[1],
                            ),
                            reviewed: reviewed,
                            isExtra: true,
                            onReview: () => controller.onExtraReview(
                              context: context,
                              drink: drink,
                              extraKey: extraKey,
                            ),
                          );
                        }),

                        // 追加ボタン
                        ExtraPickupCard(
                          freeTokens: tokens.free,
                          paidTokens: tokens.paid,
                          onPickup: (tier, useType) => controller.onPickup(tier, useType, reviews, context),
                        ),
                      ],
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── ローディング ─────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kGold),
          SizedBox(height: 16),
          Text(
            'ソムリエが選んでいます...',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 3,
              color: kDim,
            ),
          ),
        ],
      ),
    );
  }
}
