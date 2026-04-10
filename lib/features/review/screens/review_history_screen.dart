// ══════════════════════════════════════════════════════════
// レビュー履歴画面
// ══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants.dart';
import '../../../widgets/actions/purchase_links.dart';
import '../../../widgets/cards/category_tag.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../../widgets/media/drink_image.dart';
import '../../common/models/taste_profile.dart';
import '../models/review.dart';
import '../providers/review_provider.dart';

class ReviewHistoryScreen extends ConsumerStatefulWidget {
  final String uid;
  const ReviewHistoryScreen({super.key, required this.uid});

  @override
  ConsumerState<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends ConsumerState<ReviewHistoryScreen> {
  int _visibleCount = kPageSize;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        setState(() => _visibleCount += kPageSize);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(reviewsProvider(widget.uid));
    final visible = history.take(_visibleCount).toList();
    return Scaffold(
      appBar: nomigatariAppBar(title: 'レビュー履歴', onBack: () => Navigator.of(context).pop()),
      body: history.isEmpty
          ? const Center(child: Text('まだレビューがありません', style: TextStyle(fontSize: 13, color: kDim)))
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: visible.length + 1,
              itemBuilder: (_, i) {
                if (i == visible.length) {
                  if (_visibleCount < history.length) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: kGold),
                    ));
                  }
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child:
                        Text('すべて表示しました', style: TextStyle(fontSize: 10, color: Color(0xFF2a2018), letterSpacing: 2)),
                  ));
                }
                final h = visible[i];
                return _ReviewHistoryCard(review: h, uid: widget.uid);
              },
            ),
    );
  }
}

class _ReviewHistoryCard extends StatelessWidget {
  final Review review;
  final String uid;
  const _ReviewHistoryCard({required this.review, required this.uid});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0a0806),
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(3),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DrinkImage(name: review.name, category: review.category, height: 80),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(review.name, style: const TextStyle(fontSize: 14, color: kGold)),
                Text(DateFormat('yyyy年M月d日').format(review.createdAt.toDate()),
                    style: const TextStyle(fontSize: 10, color: kDim)),
              ]),
              const SizedBox(height: 6),
              Wrap(spacing: 5, runSpacing: 4, children: [
                CategoryTag(review.category),
                if (review.justRight) const CategoryTag('⭐ お気に入り', color: Color(0xFF7aaa6a)),
              ]),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: kAxes
                    .map((ax) => Text(
                          '${ax.emoji} ${axisLabel(_getVal(review.sliders, ax.key), ax)}',
                          style: const TextStyle(fontSize: 10, color: kDim),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              Text(review.text, style: const TextStyle(fontSize: 12, color: kMuted, height: 1.7)),
              const SizedBox(height: 6),
              PurchaseLinks(name: review.name),
            ]),
          ),
        ]),
      );

  int _getVal(TasteProfile s, String key) {
    switch (key) {
      case 'sweet':
        return s.sweet;
      case 'body':
        return s.body;
      case 'aroma':
        return s.aroma;
      case 'finish':
        return s.finish;
      default:
        return s.kick;
    }
  }
}
