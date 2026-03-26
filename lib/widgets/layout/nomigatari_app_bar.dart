// ============================================================
// ページ共通AppBar
// ============================================================

import 'package:flutter/material.dart';

import '../../utils/constants.dart';

// ── ページ共通AppBar ──────────────────────────────────────
AppBar nomigatariAppBar({
  required String title,
  String? subtitle,
  List<Widget>? actions,
  bool showBack = true,
  VoidCallback? onBack,
}) =>
    AppBar(
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
          if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 10, color: kDim, letterSpacing: 1)),
        ],
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: kBorder),
      ),
    );
