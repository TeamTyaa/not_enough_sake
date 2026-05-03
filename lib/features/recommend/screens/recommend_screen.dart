// ══════════════════════════════════════════════════════════
// おすすめ画面
// ══════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../../../widgets/feedback/error_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../review/providers/review_provider.dart';
import '../../token/providers/token_provider.dart';
import '../controllers/recommend_controller.dart';
import '../providers/recommend_provider.dart';
import '../widgets/drink_card.dart';
import '../widgets/extra_pickup_card.dart';

class RecommendScreen extends ConsumerStatefulWidget {
  const RecommendScreen({super.key});

  @override
  ConsumerState<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends ConsumerState<RecommendScreen> {
  bool _initCalled = false;
  bool _prevCanFetch = true;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final reviews = ref.watch(reviewsProvider(user.uid));
    final recs = ref.watch(recsProvider((user.uid, user.genres)));
    final tokens = ref.watch(tokenProvider(user.uid));

    final controller = RecommendController(ref, user);

    // クールダウン中は毎分 setState してクールダウン明けを検知する
    if (!recs.canFetch) {
      _cooldownTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (_cooldownTimer != null) {
      _cooldownTimer!.cancel();
      _cooldownTimer = null;
    }

    // 初回フェッチ、またはクールダウン明けで自動リフェッチ
    if (!_initCalled || (!_prevCanFetch && recs.canFetch)) {
      _initCalled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.initIfNeeded(recs, reviews);
      });
    }
    _prevCanFetch = recs.canFetch;

    return RefreshIndicator(
      color: kGold,
      backgroundColor: kCard,
      // クールダウン中は pull-to-refresh を無効化
      onRefresh: recs.canFetch ? () => controller.refresh(reviews) : () async {},
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
                    onRetry: recs.canFetch ? () => controller.refresh(reviews) : null,
                    onDismiss: () => ref
                        .read(recsProvider((user.uid, user.genres)).notifier)
                        .clearError(),
                  ),

                // クールダウンバナー
                if (!recs.canFetch)
                  _CooldownBanner(remaining: recs.cooldownRemaining),

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
                          final drink = recs.recs?[tier.key];
                          if (drink == null) return const SizedBox.shrink();
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
                          final drink = entry.value;
                          final extraKey = 'extra_$idx';
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

// ── クールダウンバナー ────────────────────────────────────
class _CooldownBanner extends StatefulWidget {
  final Duration remaining;
  const _CooldownBanner({required this.remaining});

  @override
  State<_CooldownBanner> createState() => _CooldownBannerState();
}

class _CooldownBannerState extends State<_CooldownBanner> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remaining;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(minutes: 1);
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final label = h > 0 ? '$h時間$m分' : '$m分';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1208),
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(children: [
        const Text('⏱', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, height: 1.6),
              children: [
                const TextSpan(text: '次の提案まで ', style: TextStyle(color: kDim)),
                TextSpan(text: label, style: const TextStyle(color: kGold)),
                const TextSpan(text: '\nトークンで追加ピックアップは今すぐ使えます', style: TextStyle(color: kDim, fontSize: 11)),
              ],
            ),
          ),
        ),
      ]),
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
