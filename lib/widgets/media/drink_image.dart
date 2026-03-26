// ============================================================
// お酒画像ウィジェット
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../services/api/image_api.dart';
import '../../utils/constants.dart';

class DrinkImage extends StatefulWidget {
  final String name;
  final String category;
  final double height;
  final double? width;

  const DrinkImage({
    super.key,
    required this.name,
    required this.category,
    this.height = 120,
    this.width,
  });

  @override
  State<DrinkImage> createState() => _DrinkImageState();
}

class _DrinkImageState extends State<DrinkImage> {
  String? _imageUrl;
  final bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    final url = await ImageApi.fetchDrinkImage(widget.name, widget.category);
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
    if (category.contains('日本酒')) return [const Color(0xFF2a1f3d), const Color(0xFF4a3060)];
    if (category.contains('ワイン')) return [const Color(0xFF3d1020), const Color(0xFF7a2040)];
    if (category.contains('ウイスキー')) return [const Color(0xFF2a1800), const Color(0xFF6a4010)];
    if (category.contains('ビール')) return [const Color(0xFF1a2a10), const Color(0xFF4a6020)];
    if (category.contains('焼酎')) return [const Color(0xFF1a2030), const Color(0xFF304060)];
    if (category.contains('ジン') || category.contains('ウォッカ') || category.contains('ラム')) {
      return [const Color(0xFF102030), const Color(0xFF205060)];
    }
    if (category.contains('梅酒') || category.contains('果実酒')) return [const Color(0xFF301020), const Color(0xFF602040)];
    if (category.contains('シャンパン') || category.contains('スパークリング')) {
      return [const Color(0xFF2a2510), const Color(0xFF5a5020)];
    }
    return [const Color(0xFF1a1a1a), const Color(0xFF3a3a3a)];
  }
}
