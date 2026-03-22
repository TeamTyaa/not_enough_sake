// ============================================================
// widgets/common_widgets.dart — 共通ウィジェット
// ============================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// ── ゴールドボタン ────────────────────────────────────────
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;
  final bool outline;
  final bool danger;
  final bool loading;

  const GoldButton({
    super.key, required this.label, this.onPressed,
    this.small = false, this.outline = false,
    this.danger = false, this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final base   = danger ? kRed : kGold;
    final h      = small ? 32.0 : 44.0;
    final fs     = small ? 10.0 : 11.0;
    final px     = small ? 14.0 : 22.0;

    return SizedBox(
      height: h,
      child: outline
        ? OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: onPressed == null ? kDim : base),
              foregroundColor: onPressed == null ? kDim : base,
              padding: EdgeInsets.symmetric(horizontal: px),
              shape: const RoundedRectangleBorder(),
              textStyle: TextStyle(fontSize: fs, letterSpacing: 2),
            ),
            child: loading
              ? SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: base))
              : Text(label),
          )
        : ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: onPressed == null ? const Color(0xFF1e1c18) : base,
              foregroundColor: onPressed == null ? kDim : kBg,
              padding: EdgeInsets.symmetric(horizontal: px),
              shape: const RoundedRectangleBorder(),
              textStyle: TextStyle(fontSize: fs, letterSpacing: 2),
            ),
            child: loading
              ? SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kBg))
              : Text(label),
          ),
    );
  }
}

// ── セクションラベル ──────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: const TextStyle(
      fontSize: 9, letterSpacing: 3, color: kDim,
    )),
  );
}

// ── カテゴリタグ ──────────────────────────────────────────
class CategoryTag extends StatelessWidget {
  final String label;
  final Color? color;
  const CategoryTag(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: c.withOpacity(.28)),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: c, letterSpacing: 1)),
    );
  }
}

// ── 信頼バッジ ────────────────────────────────────────────
class TrustBadge extends StatelessWidget {
  final double? score;
  final int count;
  const TrustBadge({super.key, this.score, required this.count});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return const Text('評価なし', style: TextStyle(fontSize: 10, color: kDim));
    }
    final stars = score!.round().clamp(0, 5);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('★' * stars + '☆' * (5 - stars),
        style: const TextStyle(fontSize: 11, color: kGold)),
      const SizedBox(width: 4),
      Text('($count件)', style: const TextStyle(fontSize: 9, color: kDim)),
    ]);
  }
}

// ── エラーバナー ──────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key, required this.message, this.onRetry, this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: kRed.withOpacity(.15),
      border: Border.all(color: kRed.withOpacity(.4)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Row(children: [
      Expanded(child: Text('⚠ $message',
        style: const TextStyle(fontSize: 12, color: Color(0xFFc07070)))),
      if (onRetry != null) ...[
        const SizedBox(width: 8),
        GoldButton(label: '再試行', onPressed: onRetry, small: true, outline: true, danger: true),
      ],
      if (onDismiss != null) ...[
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: kDim),
          onPressed: onDismiss, padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    ]),
  );
}

// ── オフラインバナー ──────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  final bool offline;
  const OfflineBanner({super.key, required this.offline});

  @override
  Widget build(BuildContext context) {
    if (!offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0x33644B14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Text(
        'オフラインです。接続が回復すると自動的に同期されます。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Color(0xFFb09040), letterSpacing: 1),
      ),
    );
  }
}

// ── お酒画像ウィジェット ──────────────────────────────────
class DrinkImage extends StatefulWidget {
  final String name;
  final String category;
  final double height;
  final double? width;

  const DrinkImage({
    super.key, required this.name, required this.category,
    this.height = 120, this.width,
  });

  @override
  State<DrinkImage> createState() => _DrinkImageState();
}

class _DrinkImageState extends State<DrinkImage> {
  String? _imageUrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    final url = await ApiService.fetchDrinkImage(widget.name, widget.category);
    if (mounted && url != null) setState(() => _imageUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final emoji = getCategoryEmoji(widget.category);
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors(widget.category),
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: _imageUrl != null
        ? CachedNetworkImage(
            imageUrl: _imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => Center(
              child: Text(emoji, style: TextStyle(fontSize: widget.height * .35)),
            ),
            errorWidget: (_, __, ___) => Center(
              child: Text(emoji, style: TextStyle(fontSize: widget.height * .35)),
            ),
          )
        : Center(
            child: Text(emoji, style: TextStyle(fontSize: widget.height * .35)),
          ),
    );
  }

  static List<Color> _gradientColors(String category) {
    if (category.contains('日本酒'))   return [const Color(0xFF2a1f3d), const Color(0xFF4a3060)];
    if (category.contains('ワイン'))   return [const Color(0xFF3d1020), const Color(0xFF7a2040)];
    if (category.contains('ウイスキー')) return [const Color(0xFF2a1800), const Color(0xFF6a4010)];
    if (category.contains('ビール'))   return [const Color(0xFF1a2a10), const Color(0xFF4a6020)];
    if (category.contains('焼酎'))     return [const Color(0xFF1a2030), const Color(0xFF304060)];
    if (category.contains('ジン') || category.contains('ウォッカ') || category.contains('ラム'))
      return [const Color(0xFF102030), const Color(0xFF205060)];
    if (category.contains('梅酒') || category.contains('果実酒'))
      return [const Color(0xFF301020), const Color(0xFF602040)];
    if (category.contains('シャンパン') || category.contains('スパークリング'))
      return [const Color(0xFF2a2510), const Color(0xFF5a5020)];
    return [const Color(0xFF1a1a1a), const Color(0xFF3a3a3a)];
  }
}

// ── 購入リンクボタン ──────────────────────────────────────
class PurchaseLinks extends StatelessWidget {
  final String name;
  const PurchaseLinks({super.key, required this.name});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 6, runSpacing: 6,
    children: [
      _LinkButton(label: '📦 Amazon',  url: buildAmazonUrl(name)),
      _LinkButton(label: '🛍 楽天市場', url: buildRakutenUrl(name)),
    ],
  );
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  const _LinkButton({required this.label, required this.url});

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: kBorder),
      foregroundColor: const Color(0xFF9a8a70),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      textStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
      shape: const RoundedRectangleBorder(),
    ),
    child: Text(label),
  );
}

// ── 好みスライダー（レビュー用） ──────────────────────────
class TasteSlider extends StatelessWidget {
  final TasteAxis axis;
  final int value;          // -5 ～ +5
  final ValueChanged<int> onChanged;
  final bool showCenterBadge;

  const TasteSlider({
    super.key, required this.axis, required this.value,
    required this.onChanged, this.showCenterBadge = true,
  });

  bool get _center => value.abs() <= 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: Text('${axis.emoji} ${axis.left}',
          style: TextStyle(fontSize: 11, color: value < -1 ? kGold : kDim))),
        if (showCenterBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(
                color: _center ? kGold.withOpacity(.4) : kBorder),
              color: _center ? kGold.withOpacity(.08) : Colors.transparent,
            ),
            child: Text('ちょうどいい', style: TextStyle(
              fontSize: 9, letterSpacing: 1,
              color: _center ? kGold : const Color(0xFF2e2820),
            )),
          ),
        Expanded(child: Text(axis.right,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 11, color: value > 1 ? kGold : kDim))),
      ]),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: kGold,
          inactiveTrackColor: const Color(0xFF1a1816),
          thumbColor: _center ? const Color(0xFF7a6040) : kGold,
          overlayColor: kGold.withOpacity(.1),
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(
          min: -5, max: 5, divisions: 10,
          value: value.toDouble(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('-5', style: TextStyle(fontSize: 8, color: Color(0xFF2a2018))),
          const Text('0',  style: TextStyle(fontSize: 8, color: Color(0xFF5a4a38))),
          const Text('+5', style: TextStyle(fontSize: 8, color: Color(0xFF2a2018))),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );
}

// ── SimpleSlider（プロフィール登録用） ────────────────────
class SimpleSlider extends StatelessWidget {
  final TasteAxis axis;
  final int value;
  final ValueChanged<int> onChanged;

  const SimpleSlider({
    super.key, required this.axis, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: Text('${axis.emoji} ${axis.simpleLeft}',
          style: TextStyle(fontSize: 12, color: value < 0 ? kGold : kDim))),
        Expanded(child: Text(axis.simpleRight,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, color: value > 0 ? kGold : kDim))),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: kGold,
          inactiveTrackColor: const Color(0xFF1a1816),
          thumbColor: kGold,
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
        child: Slider(
          min: -5, max: 5, divisions: 10,
          value: value.toDouble(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('-5', style: TextStyle(fontSize: 8, color: Color(0xFF2a2018))),
          const Text('0',  style: TextStyle(fontSize: 8, color: Color(0xFF5a4a38))),
          const Text('+5', style: TextStyle(fontSize: 8, color: Color(0xFF2a2018))),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );
}

// ── 星評価入力 ────────────────────────────────────────────
class StarInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarInput({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => GestureDetector(
      onTap: () => onChanged(i + 1),
      child: Text(i < value ? '★' : '☆',
        style: TextStyle(
          fontSize: 28,
          color: i < value ? kGold : const Color(0xFF2a2420),
        )),
    )),
  );
}

// ── ジャンル選択 ──────────────────────────────────────────
class GenreSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const GenreSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: kGenres.map((g) {
      final on = selected.contains(g);
      return GestureDetector(
        onTap: () => onChanged(
          on ? selected.where((x) => x != g).toList() : [...selected, g],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: on ? kGold : const Color(0xFF2a2420)),
            color: on ? kGold.withOpacity(.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text('${on ? "✓ " : ""}$g',
            style: TextStyle(fontSize: 11, color: on ? kGold : kDim)),
        ),
      );
    }).toList(),
  );
}

// ── ページ共通AppBar ──────────────────────────────────────
AppBar nomigatorAppBar({
  required String title,
  String? subtitle,
  List<Widget>? actions,
  bool showBack = true,
  VoidCallback? onBack,
}) => AppBar(
  backgroundColor: const Color(0xFF0a0806),
  elevation: 0,
  leading: showBack
    ? IconButton(
        icon: const Icon(Icons.arrow_back, color: kDim),
        onPressed: onBack,
      )
    : null,
  automaticallyImplyLeading: false,
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 17, color: kText, letterSpacing: 1)),
      if (subtitle != null)
        Text(subtitle, style: const TextStyle(fontSize: 10, color: kDim, letterSpacing: 1)),
    ],
  ),
  actions: actions,
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(height: 1, color: kBorder),
  ),
);
