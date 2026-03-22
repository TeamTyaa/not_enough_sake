// ============================================================
// utils/constants.dart — 定数・テーマカラー
// ============================================================

import 'package:flutter/material.dart';

// ── アフィリエイト ────────────────────────────────────────
const String kAmazonAssociateId  = 'YOUR_AMAZON_ASSOCIATE_ID';
const String kRakutenAffiliateId = 'YOUR_RAKUTEN_AFFILIATE_ID';

// ── アプリ定数 ────────────────────────────────────────────
const int    kReviewThreshold    = 5;
const int    kApprovalThreshold  = 3;
const double kSimilarityThreshold = 30.0;
const int    kPageSize           = 20;
const int    kTokenFreePerReview = 1;

// ── 価格帯 ───────────────────────────────────────────────
class PriceTier {
  final String key;
  final String label;
  final String range;
  final String badge;
  final Color  color;
  const PriceTier({
    required this.key, required this.label, required this.range,
    required this.badge, required this.color,
  });
}

const List<PriceTier> kPriceTiers = [
  PriceTier(key:'low',  label:'低価格帯', range:'〜2,000円/L未満',  badge:'¥',   color:Color(0xFF7aaa6a)),
  PriceTier(key:'mid',  label:'中価格帯', range:'2,000〜4,000円/L', badge:'¥¥',  color:Color(0xFFc9a84c)),
  PriceTier(key:'high', label:'高価格帯', range:'4,000円/L〜',       badge:'¥¥¥', color:Color(0xFFc07a5a)),
];

// ── 好みスライダー軸 ──────────────────────────────────────
class TasteAxis {
  final String key;
  final String emoji;
  final String left;
  final String right;
  final String simpleLeft;
  final String simpleRight;
  const TasteAxis({
    required this.key, required this.emoji,
    required this.left, required this.right,
    required this.simpleLeft, required this.simpleRight,
  });
}

const List<TasteAxis> kAxes = [
  TasteAxis(key:'sweet',  emoji:'🍯', left:'もっと甘い方が好き',         right:'もっと辛い方が好き',         simpleLeft:'甘いのが好き',         simpleRight:'辛いのが好き'),
  TasteAxis(key:'body',   emoji:'🌊', left:'もっと軽い方が好き',         right:'もっと濃厚な方が好き',         simpleLeft:'軽いのが好き',         simpleRight:'濃厚なのが好き'),
  TasteAxis(key:'aroma',  emoji:'🌸', left:'もっとフルーティな方が好き', right:'もっとどっしりした香りが好き', simpleLeft:'フルーティな香りが好き', simpleRight:'どっしりした香りが好き'),
  TasteAxis(key:'finish', emoji:'✨', left:'もっとすっきりした方が好き', right:'もっとコクが残る方が好き',     simpleLeft:'すっきりしたのが好き',   simpleRight:'コクが残るのが好き'),
  TasteAxis(key:'kick',   emoji:'🔥', left:'もっとまろやかな方が好き',   right:'もっとキリッとした刺激が好き', simpleLeft:'まろやかなのが好き',     simpleRight:'キリッとした刺激が好き'),
];

// ── ジャンル ─────────────────────────────────────────────
const List<String> kGenres = [
  '日本酒', 'ワイン', 'ウイスキー・バーボン',
  'ビール・クラフトビール', '焼酎',
  'ジン・ウォッカ・ラム', '梅酒・果実酒', 'シャンパン・スパークリング',
];

// ── 予算 ─────────────────────────────────────────────────
const List<String> kBudgetOptions = [
  '〜1,000円', '〜2,000円', '〜3,000円', '〜5,000円', '5,000円〜',
];

// ── トークンプラン ────────────────────────────────────────
class TokenPlan {
  final String id;
  final int price;
  final int paid;
  final String label;
  final String desc;
  const TokenPlan({
    required this.id, required this.price, required this.paid,
    required this.label, required this.desc,
  });
}

const List<TokenPlan> kTokenPlans = [
  TokenPlan(id:'t100',  price:100,  paid:3,  label:'100円',   desc:'3升'),
  TokenPlan(id:'t500',  price:500,  paid:18, label:'500円',   desc:'18升'),
  TokenPlan(id:'t1000', price:1000, paid:45, label:'1,000円', desc:'45升'),
];

// ── 通報理由 ─────────────────────────────────────────────
const List<String> kReportReasons = [
  'スパム・宣伝', '不適切なコンテンツ', '虚偽の情報',
  'ハラスメント・差別的表現', 'その他',
];

// ── テーマカラー ──────────────────────────────────────────
const Color kBg    = Color(0xFF12100d);
const Color kCard  = Color(0xFF0c0a07);
const Color kBorder= Color(0xFF1e1c18);
const Color kGold  = Color(0xFFc9a84c);
const Color kText  = Color(0xFFede0c8);
const Color kMuted = Color(0xFF7a6a58);
const Color kDim   = Color(0xFF4a3a28);
const Color kRed   = Color(0xFF8a4040);
const Color kGreen = Color(0xFF7aaa6a);

// テーマデータ
final ThemeData kAppTheme = ThemeData(
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(
    primary:    kGold,
    secondary:  kGold,
    surface:    kCard,
    onPrimary:  kBg,
    onSurface:  kText,
  ),
  fontFamily: 'serif',
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0a0806),
    foregroundColor: kText,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: kText, fontSize: 17, letterSpacing: 1, fontFamily: 'serif',
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: kMuted, fontSize: 13, height: 1.8),
    bodySmall:  TextStyle(color: kDim,   fontSize: 10, letterSpacing: 1),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kGold,
      foregroundColor: kBg,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      textStyle: const TextStyle(letterSpacing: 2, fontSize: 11),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF080604),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: Color(0xFF4a3a28)),
    ),
    hintStyle: const TextStyle(color: kDim, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
  ),
  dividerColor: kBorder,
);

// ── カテゴリ絵文字マッピング ──────────────────────────────
const Map<String, String> kCategoryEmoji = {
  '日本酒':                 '🍶',
  'ワイン':                 '🍷',
  'ウイスキー・バーボン':    '🥃',
  'ビール・クラフトビール':  '🍺',
  '焼酎':                   '🫙',
  'ジン・ウォッカ・ラム':    '🍸',
  '梅酒・果実酒':            '🍑',
  'シャンパン・スパークリング':'🥂',
};

String getCategoryEmoji(String category) {
  for (final entry in kCategoryEmoji.entries) {
    if (category.contains(entry.key.split('・').first)) return entry.value;
  }
  return '🍾';
}

// ── ユーティリティ ────────────────────────────────────────
String axisLabel(int value, TasteAxis axis) {
  if (value < -2) return axis.left.replaceAll('もっと', '').replaceAll('方が好き', '');
  if (value >  2) return axis.right.replaceAll('もっと', '').replaceAll('方が好き', '');
  return 'ちょうどいい';
}

String buildAmazonUrl(String name) {
  final q = Uri.encodeComponent('$name お酒');
  return 'https://www.amazon.co.jp/s?k=$q&tag=$kAmazonAssociateId';
}

String buildRakutenUrl(String name) {
  final q = Uri.encodeComponent(name);
  return 'https://search.rakuten.co.jp/search/mall/$q/';
}
