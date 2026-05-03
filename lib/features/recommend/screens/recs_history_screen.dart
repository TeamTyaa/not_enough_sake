// ══════════════════════════════════════════════════════════
// おすすめ履歴画面
// ══════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../review/models/favorite.dart';
import '../../review/models/review.dart';
import '../../review/providers/favorite_provider.dart';
import '../../review/providers/review_provider.dart';
import '../../review/screens/review_screen.dart';
import '../../token/providers/token_provider.dart';
import '../models/recs_history_item.dart';
import '../models/recommended_drink.dart';
import '../providers/recs_history_provider.dart';
import '../widgets/drink_card.dart';

class RecsHistoryScreen extends ConsumerWidget {
  const RecsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    final historyAsync = ref.watch(recsHistoryProvider(user.uid));
    final reviews = ref.watch(reviewsProvider(user.uid));

    return Scaffold(
      appBar: nomigatariAppBar(
        title: 'おすすめ履歴',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kGold)),
        error: (e, _) => const Center(
          child: Text('読み込みに失敗しました', style: TextStyle(color: kDim)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'まだ履歴がありません。\nおすすめを取得すると記録されます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kDim, height: 1.8),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 40),
            itemCount: items.length,
            itemBuilder: (context, i) => _HistoryBatch(
              item: items[i],
              reviews: reviews,
            ),
          );
        },
      ),
    );
  }
}

// ── バッチ（1回分のおすすめ） ──────────────────────────────
class _HistoryBatch extends ConsumerWidget {
  final RecsHistoryItem item;
  final List<Review> reviews;

  const _HistoryBatch({
    required this.item,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = DateFormat('yyyy年M月d日 (E)', 'ja').format(item.fetchedAt);
    final uid = ref.read(authProvider).user!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付ヘッダー
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, letterSpacing: 2, color: kDim),
          ),
        ),

        // カード横スクロール
        SizedBox(
          height: 430,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: kPriceTiers.map((tier) {
              final drink = item.recs[tier.key];
              if (drink == null) return const SizedBox.shrink();
              final reviewed = reviews.any((r) => r.name == drink.name);

              return DrinkCard(
                drink: drink,
                tier: tier,
                reviewed: reviewed,
                onReview: reviewed
                    ? () {}
                    : () => _openReview(context, ref, uid, drink, tier.label),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _openReview(
    BuildContext context,
    WidgetRef ref,
    String uid,
    RecommendedDrink drink,
    String tierLabel,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          drink: drink,
          tierLabel: tierLabel,
          uid: uid,
          onSaved: (r) => _handleSaved(ref, uid, r, drink),
        ),
      ),
    );
  }

  Future<void> _handleSaved(
    WidgetRef ref,
    String uid,
    Review r,
    RecommendedDrink drink,
  ) async {
    final id = await ref.read(reviewsProvider(uid).notifier).addReview(r);
    await ref.read(tokenProvider(uid).notifier).addFree(1);

    if (r.justRight) {
      final favs = ref.read(favoritesProvider(uid));
      if (!favs.any((f) => f.name == drink.name && f.category == drink.category)) {
        await ref.read(favoritesProvider(uid).notifier).setFavorites([
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
  }
}
