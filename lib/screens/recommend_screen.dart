import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../utils/constants.dart';
import '../widgets/common_widgets.dart';
import 'review_screen.dart';

class RecommendScreen extends ConsumerWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(authProvider).user!;
    final reviews = ref.watch(reviewsProvider(user.uid));
    final recs    = ref.watch(recsProvider((user.uid, user.genres)));
    final tokens  = ref.watch(tokenProvider(user.uid));

    // 初回自動フェッチ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!recs.isLoading && recs.recs == null && recs.error == null) {
        ref.read(recsProvider((user.uid, user.genres)).notifier)
          .fetchRecs(user.tasteProfile, reviews);
      }
    });

    return RefreshIndicator(
      color: kGold,
      backgroundColor: kCard,
      onRefresh: () => ref.read(recsProvider((user.uid, user.genres)).notifier)
        .fetchRecs(user.tasteProfile, reviews),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (recs.error != null)
                  ErrorBanner(
                    message: recs.error!,
                    onRetry: () => ref.read(recsProvider((user.uid, user.genres)).notifier)
                      .fetchRecs(user.tasteProfile, reviews),
                  ),
                const Text(
                  '価格帯ごとに1本ずつ。レビューするごとに1合トークンがもらえます。',
                  style: TextStyle(fontSize: 12, color: kDim, height: 1.7),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          // ── カード横スクロール ─────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 460,
              child: recs.isLoading
                ? const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: kGold),
                      SizedBox(height: 16),
                      Text('ソムリエが選んでいます...', style: TextStyle(
                        fontSize: 12, letterSpacing: 3, color: kDim,
                      )),
                    ]),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // 通常3本
                      ...kPriceTiers.map((tier) {
                        final drinkMap = recs.recs?[tier.key] as Map<String, dynamic>?;
                        if (drinkMap == null) return const SizedBox.shrink();
                        final drink = RecommendedDrink.fromMap(drinkMap, tier.key);
                        final reviewed = recs.done[tier.key] ?? false;
                        return _DrinkCard(
                          drink: drink, tier: tier, reviewed: reviewed,
                          uid: user.uid,
                          onReview: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ReviewScreen(
                              drink: drink,
                              tierLabel: tier.label,
                              uid: user.uid,
                              onSaved: (r) async {
                                await ref.read(reviewsProvider(user.uid).notifier)
                                  .addReview(r);
                                await ref.read(tokenProvider(user.uid).notifier)
                                  .addFree(kTokenFreePerReview);
                                if (r.justRight) {
                                  final favs = ref.read(favoritesProvider(user.uid));
                                  if (!favs.any((f) => f.name == drink.name)) {
                                    final newFavs = [...favs,
                                      FavoriteItem(id: r.id, name: drink.name,
                                        category: drink.category)];
                                    await ref.read(favoritesProvider(user.uid).notifier)
                                      .setFavorites(newFavs);
                                  }
                                }
                                ref.read(recsProvider((user.uid, user.genres)).notifier)
                                  .markDone(tier.key);
                                final updatedReviews = ref.read(reviewsProvider(user.uid));
                                final allDone = kPriceTiers.every((t) =>
                                  (ref.read(recsProvider((user.uid, user.genres))).done[t.key] ?? false)
                                  || t.key == tier.key);
                                if (allDone) {
                                  await ref.read(recsProvider((user.uid, user.genres)).notifier)
                                    .fetchRecs(user.tasteProfile, updatedReviews);
                                }
                              },
                            )),
                          ),
                        );
                      }),

                      // 追加ピックアップ
                      ...recs.extraRecs.asMap().entries.map((entry) {
                        final idx     = entry.key;
                        final extra   = entry.value;
                        final extraKey= 'extra_$idx';
                        final reviewed = recs.done[extraKey] ?? false;
                        final drink = RecommendedDrink.fromMap(extra, extra['priceKey'] ?? 'mid');
                        return _DrinkCard(
                          drink: drink,
                          tier: kPriceTiers.firstWhere(
                            (t) => t.key == drink.priceKey,
                            orElse: () => kPriceTiers[1],
                          ),
                          reviewed: reviewed,
                          uid: user.uid,
                          isExtra: true,
                          onReview: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ReviewScreen(
                              drink: drink,
                              tierLabel: '追加ピックアップ',
                              uid: user.uid,
                              onSaved: (r) async {
                                await ref.read(reviewsProvider(user.uid).notifier)
                                  .addReview(r);
                                await ref.read(tokenProvider(user.uid).notifier)
                                  .addFree(kTokenFreePerReview);
                                ref.read(recsProvider((user.uid, user.genres)).notifier)
                                  .markDone(extraKey);
                              },
                            )),
                          ),
                        );
                      }),

                      // 追加ボタン
                      _ExtraPickupCard(
                        freeTokens: tokens.free,
                        paidTokens: tokens.paid,
                        onPickup: (tier, useType) async {
                          final ok = useType == 'free'
                            ? await ref.read(tokenProvider(user.uid).notifier).spendFree(10)
                            : await ref.read(tokenProvider(user.uid).notifier).spendPaid(1);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('トークンが不足しています')));
                            return;
                          }
                          await ref.read(recsProvider((user.uid, user.genres)).notifier)
                            .fetchExtraPickup(
                              tier: tier,
                              taste: user.tasteProfile,
                              history: reviews,
                              genres: user.genres,
                            );
                        },
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

// ── 飲み物カード ──────────────────────────────────────────
class _DrinkCard extends StatelessWidget {
  final RecommendedDrink drink;
  final PriceTier tier;
  final bool reviewed;
  final String uid;
  final bool isExtra;
  final VoidCallback onReview;

  const _DrinkCard({
    required this.drink, required this.tier, required this.reviewed,
    required this.uid, this.isExtra = false, required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: reviewed ? kGold.withOpacity(.04) : kCard,
        border: Border.all(
          color: isExtra
            ? kGold.withOpacity(.2)
            : reviewed ? kGold.withOpacity(.3) : kBorder,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 画像
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          child: DrinkImage(name: drink.name, category: drink.category, height: 130),
        ),

        // 価格帯バー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: const BoxDecoration(
            color: Color(0xFF0a0806),
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text(tier.badge, style: TextStyle(fontSize: 10, color: tier.color)),
              const SizedBox(width: 6),
              Text(tier.label, style: const TextStyle(fontSize: 10, color: kDim)),
              if (isExtra) ...[
                const SizedBox(width: 6),
                const Text('✦ 追加', style: TextStyle(fontSize: 10, color: kGold)),
              ],
            ]),
            if (reviewed)
              const Text('✓ 済み', style: TextStyle(fontSize: 9, color: kGreen)),
          ]),
        ),

        // 本文
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryTag(drink.category),
                const SizedBox(height: 8),
                Text(drink.name, style: const TextStyle(
                  fontSize: 15, color: kText, height: 1.4,
                )),
                const SizedBox(height: 5),
                Expanded(child: Text(drink.description, style: const TextStyle(
                  fontSize: 12, color: kMuted, height: 1.75,
                ))),
                if (drink.profile != null) ...[
                  Text('🍷 ${drink.profile}',
                    style: const TextStyle(fontSize: 11, color: kDim)),
                ],
                if (drink.occasion != null) ...[
                  const SizedBox(height: 2),
                  Text('✦ ${drink.occasion}',
                    style: const TextStyle(fontSize: 11, color: kDim)),
                ],
                const SizedBox(height: 8),
                PurchaseLinks(name: drink.name),
                if (!reviewed) ...[
                  const SizedBox(height: 12),
                  GoldButton(
                    label: '飲んだ！レビュー →',
                    small: true,
                    onPressed: onReview,
                  ),
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── 追加ピックアップボタン ────────────────────────────────
class _ExtraPickupCard extends StatelessWidget {
  final int freeTokens;
  final int paidTokens;
  final Future<void> Function(String tier, String useType) onPickup;

  const _ExtraPickupCard({
    required this.freeTokens, required this.paidTokens, required this.onPickup,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _showDialog(context),
    child: Container(
      width: 140,
      decoration: BoxDecoration(
        border: Border.all(color: kBorder, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('＋', style: TextStyle(fontSize: 26, color: kDim)),
        const SizedBox(height: 8),
        const Text('追加ピックアップ',
          style: TextStyle(fontSize: 10, color: kDim, height: 1.6),
          textAlign: TextAlign.center),
        const Text('10合 or 1升',
          style: TextStyle(fontSize: 10, color: kDim)),
        const SizedBox(height: 4),
        Text('${freeTokens}合 / ${paidTokens}升',
          style: const TextStyle(fontSize: 9, color: Color(0xFF3a3028))),
      ]),
    ),
  );

  void _showDialog(BuildContext context) {
    String selectedTier = 'low';
    String selectedUse  = 'free';
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('追加ピックアップ', style: TextStyle(
              fontSize: 15, color: kText, letterSpacing: 1,
            )),
            const SizedBox(height: 20),
            // 価格帯選択
            Row(children: kPriceTiers.map((t) => Expanded(
              child: GestureDetector(
                onTap: () => setS(() => selectedTier = t.key),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedTier == t.key ? t.color : kBorder),
                    color: selectedTier == t.key
                      ? kGold.withOpacity(.1) : Colors.transparent,
                  ),
                  child: Column(children: [
                    Text(t.badge, style: TextStyle(color: t.color, fontSize: 14)),
                    Text(t.label, style: const TextStyle(fontSize: 10, color: kDim)),
                  ]),
                ),
              ),
            )).toList()),
            const SizedBox(height: 16),
            // トークン選択
            Row(children: [
              _TokenChoice(
                label: '10合', sub: '(残${freeTokens}合)',
                selected: selectedUse == 'free',
                enabled: freeTokens >= 10,
                onTap: () => setS(() => selectedUse = 'free'),
              ),
              const SizedBox(width: 12),
              _TokenChoice(
                label: '1升', sub: '(残${paidTokens}升)',
                selected: selectedUse == 'paid',
                enabled: paidTokens >= 1,
                onTap: () => setS(() => selectedUse = 'paid'),
              ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: GoldButton(
                label: 'ピックアップする',
                onPressed: (selectedUse == 'free' ? freeTokens >= 10 : paidTokens >= 1)
                  ? () {
                      Navigator.of(ctx).pop();
                      onPickup(selectedTier, selectedUse);
                    }
                  : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: GoldButton(
                label: 'キャンセル', outline: true,
                onPressed: () => Navigator.of(ctx).pop(),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _TokenChoice extends StatelessWidget {
  final String label, sub;
  final bool selected, enabled;
  final VoidCallback onTap;
  const _TokenChoice({
    required this.label, required this.sub, required this.selected,
    required this.enabled, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? kGold : kBorder),
          color: selected ? kGold.withOpacity(.1) : Colors.transparent,
        ),
        child: Column(children: [
          Text(label, style: TextStyle(
            fontSize: 13, color: enabled ? (selected ? kGold : kMuted) : kDim)),
          Text(sub, style: const TextStyle(fontSize: 9, color: kDim)),
        ]),
      ),
    ),
  );
}
