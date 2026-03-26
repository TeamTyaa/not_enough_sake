// ============================================================
// 購入リンクボタン
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';

class PurchaseLinks extends StatelessWidget {
  final String name;
  const PurchaseLinks({super.key, required this.name});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _LinkButton(label: '📦 Amazon', url: buildAmazonUrl(name)),
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
