import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';
import '../../../widgets/cards/category_tag.dart';
import '../../../widgets/inputs/taste_slider.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../../widgets/media/drink_image.dart';
import '../../common/models/taste_profile.dart';
import '../../recommend/models/recommended_drink.dart';
import '../models/drink_review.dart';

class ReviewScreen extends StatefulWidget {
  final RecommendedDrink drink;
  final String tierLabel;
  final String uid;
  final Future<void> Function(DrinkReview) onSaved;

  const ReviewScreen({
    super.key,
    required this.drink,
    required this.tierLabel,
    required this.uid,
    required this.onSaved,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  TasteProfile _sliders = const TasteProfile();
  final _textCtrl = TextEditingController();
  bool _loading = false;
  String _err = '';

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  bool get _justRight => _sliders.isJustRight;

  Future<void> _save() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _err = '';
    });
    try {
      final review = DrinkReview(
        id: '', // DB側で採番
        name: widget.drink.name,
        category: widget.drink.category,
        tier: widget.drink.priceKey,
        sliders: _sliders,
        text: _textCtrl.text.trim(),
        justRight: _justRight,
        date: DateTime.now().toString().split(' ').first.replaceAll('-', '/'),
        officialUrl: widget.drink.officialUrl,
      );
      await widget.onSaved(review);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _err = '保存に失敗しました。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: nomigatariAppBar(
          title: 'レビューを書く',
          subtitle: widget.tierLabel,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // お酒情報カード
            Container(
              decoration: BoxDecoration(
                color: kCard,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(3),
              ),
              clipBehavior: Clip.hardEdge,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 90,
                  child: DrinkImage(
                    name: widget.drink.name,
                    category: widget.drink.category,
                    height: 90,
                    width: 90,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CategoryTag(widget.drink.category),
                      const SizedBox(height: 6),
                      Text(widget.drink.name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: kText,
                          )),
                      if (widget.drink.profile != null) ...[
                        const SizedBox(height: 4),
                        Text('🍷 ${widget.drink.profile}', style: const TextStyle(fontSize: 11, color: kDim)),
                      ],
                      if (widget.drink.occasion != null)
                        Text('✦ ${widget.drink.occasion}', style: const TextStyle(fontSize: 11, color: kDim)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ちょうどいいバッジ
            if (_justRight)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.08),
                  border: Border.all(color: kGold.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  '⭐ すべてちょうどいい！お気に入りに登録されます',
                  style: TextStyle(fontSize: 12, color: kGold),
                ),
              ),

            // スライダー
            const Text('— 飲んでみてどうでしたか？ —', style: TextStyle(fontSize: 9, letterSpacing: 3, color: kDim)),
            const SizedBox(height: 16),
            ...kAxes.map((ax) => TasteSlider(
                  axis: ax,
                  value: _getAxisValue(ax.key),
                  onChanged: (v) => setState(() => _sliders = _setAxisValue(ax.key, v)),
                )),

            // コメント
            const SizedBox(height: 4),
            const Text('コメント', style: TextStyle(fontSize: 9, letterSpacing: 2, color: kDim)),
            const SizedBox(height: 8),
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              style: const TextStyle(color: kText, fontSize: 13, height: 1.85),
              decoration: const InputDecoration(
                hintText: '香り、飲んだシーン、合わせた料理、次に試したいものなど…',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            if (_err.isNotEmpty) ...[
              Text(_err, style: const TextStyle(fontSize: 12, color: kRed)),
              const SizedBox(height: 12),
            ],

            Row(children: [
              GoldButton(
                label: 'レビューを保存 →',
                loading: _loading,
                onPressed: _textCtrl.text.trim().isNotEmpty ? _save : null,
              ),
              const SizedBox(width: 12),
              GoldButton(
                label: 'キャンセル',
                outline: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
            const SizedBox(height: 40),
          ]),
        ),
      );

  int _getAxisValue(String key) {
    switch (key) {
      case 'sweet':
        return _sliders.sweet;
      case 'body':
        return _sliders.body;
      case 'aroma':
        return _sliders.aroma;
      case 'finish':
        return _sliders.finish;
      case 'kick':
        return _sliders.kick;
      default:
        return 0;
    }
  }

  TasteProfile _setAxisValue(String key, int v) => TasteProfile(
        sweet: key == 'sweet' ? v : _sliders.sweet,
        body: key == 'body' ? v : _sliders.body,
        aroma: key == 'aroma' ? v : _sliders.aroma,
        finish: key == 'finish' ? v : _sliders.finish,
        kick: key == 'kick' ? v : _sliders.kick,
      );
}
