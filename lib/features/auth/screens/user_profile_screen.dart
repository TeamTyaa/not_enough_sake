// ============================================================
// ユーザープロフィール画面
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants.dart';
import '../../../widgets/cards/category_tag.dart';
import '../../../widgets/cards/section_label.dart';
import '../../../widgets/feedback/error_banner.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../../widgets/media/drink_image.dart';
import '../../common/models/taste_profile.dart';
import '../../review/models/favorite.dart';
import '../../review/models/review.dart';
import '../../review/repositories/favorite_repository.dart';
import '../../review/repositories/review_repository.dart';

class UserProfileScreen extends StatefulWidget {
  final String nick;
  final String uid;

  const UserProfileScreen({super.key, required this.nick, required this.uid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Review> _reviews = [];
  List<Favorite> _favs = [];
  bool _loading = true;
  String _err = '';
  int _visibleCount = 10;
  final _scrollCtrl = ScrollController();
  final _favoriteRepository = FavoriteRepository();
  final _reviewRepository = ReviewRepository();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        setState(() => _visibleCount += 10);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final reviews = await _reviewRepository.getReviews(widget.uid);
      final favs = await _favoriteRepository.getFavorites(widget.uid);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _favs = favs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = '読み込みに失敗しました';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: nomigatariAppBar(
          title: '${widget.nick} さんのプロフィール',
          onBack: () => Navigator.of(context).pop(),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kGold))
            : ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  if (_err.isNotEmpty) ErrorBanner(message: _err, onDismiss: () => setState(() => _err = '')),

                  // ── お気に入りランキング ────────────────────────
                  if (_favs.isNotEmpty) ...[
                    SectionLabel('FAVORITES RANKING'),
                    ..._favs.take(5).toList().asMap().entries.map((entry) {
                      final i = entry.key;
                      final fav = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1a1816)))),
                        child: Row(children: [
                          SizedBox(
                            width: 24,
                            child: Text('${i + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: i == 0
                                      ? kGold
                                      : i == 1
                                          ? const Color(0xFF9a9a9a)
                                          : i == 2
                                              ? const Color(0xFFc07a5a)
                                              : kDim,
                                )),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: DrinkImage(
                              name: fav.name,
                              category: fav.category,
                              height: 44,
                              width: 44,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fav.name, style: const TextStyle(fontSize: 13, color: kText)),
                            Text(fav.category, style: const TextStyle(fontSize: 10, color: kDim)),
                          ])),
                        ]),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // ── レビュー履歴 ────────────────────────────────
                  SectionLabel('REVIEW HISTORY — ${_reviews.length}本'),
                  if (_reviews.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('まだレビューがありません', style: TextStyle(fontSize: 13, color: kDim)),
                    ))
                  else ...[
                    ..._reviews.take(_visibleCount).map((h) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0a0806),
                            border: Border.all(color: kBorder),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            DrinkImage(name: h.name, category: h.category, height: 70),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(h.name, style: const TextStyle(fontSize: 14, color: kGold)),
                                  Text(DateFormat('yyyy年M月d日').format(h.createdAt.toDate()),
                                      style: const TextStyle(fontSize: 10, color: kDim)),
                                ]),
                                const SizedBox(height: 6),
                                Wrap(spacing: 5, runSpacing: 4, children: [
                                  CategoryTag(h.category),
                                  if (h.justRight) const CategoryTag('⭐ お気に入り', color: Color(0xFF7aaa6a)),
                                ]),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: kAxes
                                      .map((ax) => Text(
                                            '${ax.emoji} ${axisLabel(_getAxisValue(h.sliders, ax.key), ax)}',
                                            style: const TextStyle(fontSize: 10, color: kDim),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 6),
                                Text(h.text, style: const TextStyle(fontSize: 12, color: kMuted, height: 1.7)),
                              ]),
                            ),
                          ]),
                        )),
                    if (_visibleCount < _reviews.length)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(color: kGold),
                      )),
                    if (_visibleCount >= _reviews.length && _reviews.isNotEmpty)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('すべて表示しました',
                            style: TextStyle(fontSize: 10, color: Color(0xFF2a2018), letterSpacing: 2)),
                      )),
                  ],
                ],
              ),
      );

  int _getAxisValue(TasteProfile s, String key) {
    switch (key) {
      case 'sweet':
        return s.sweet;
      case 'body':
        return s.body;
      case 'aroma':
        return s.aroma;
      case 'finish':
        return s.finish;
      case 'kick':
        return s.kick;
      default:
        return 0;
    }
  }
}
