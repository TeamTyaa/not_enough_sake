// ============================================================
// 好みプロファイルモデル
// ============================================================

import 'dart:math';

class TasteProfile {
  final int sweet; // -5(甘い) ～ +5(辛い)
  final int body; // -5(軽い) ～ +5(濃厚)
  final int aroma; // -5(フルーティ) ～ +5(どっしり)
  final int finish; // -5(すっきり) ～ +5(コク残る)
  final int kick; // -5(まろやか) ～ +5(キリッと)

  const TasteProfile({
    this.sweet = 0,
    this.body = 0,
    this.aroma = 0,
    this.finish = 0,
    this.kick = 0,
  });

  factory TasteProfile.fromMap(Map<String, dynamic> m) => TasteProfile(
        sweet: (m['sweet'] ?? 0) as int,
        body: (m['body'] ?? 0) as int,
        aroma: (m['aroma'] ?? 0) as int,
        finish: (m['finish'] ?? 0) as int,
        kick: (m['kick'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'sweet': sweet,
        'body': body,
        'aroma': aroma,
        'finish': finish,
        'kick': kick,
      };

  TasteProfile copyWith({
    int? sweet,
    int? body,
    int? aroma,
    int? finish,
    int? kick,
  }) =>
      TasteProfile(
        sweet: sweet ?? this.sweet,
        body: body ?? this.body,
        aroma: aroma ?? this.aroma,
        finish: finish ?? this.finish,
        kick: kick ?? this.kick,
      );

  bool get isJustRight =>
      sweet.abs() <= 1 && body.abs() <= 1 && aroma.abs() <= 1 && finish.abs() <= 1 && kick.abs() <= 1;

  double distanceTo(TasteProfile other) {
    final ds = sweet - other.sweet;
    final db = body - other.body;
    final da = aroma - other.aroma;
    final df = finish - other.finish;
    final dk = kick - other.kick;
    return sqrt((ds * ds + db * db + da * da + df * df + dk * dk).toDouble());
  }

  static TasteProfile average(List<TasteProfile> list) {
    TasteProfile tasteProfile = TasteProfile();
    if (list.isNotEmpty) {
      tasteProfile = tasteProfile.copyWith(
        sweet: (list.map((e) => e.sweet).reduce((a, b) => a + b) / list.length).round(),
        body: (list.map((e) => e.body).reduce((a, b) => a + b) / list.length).round(),
        aroma: (list.map((e) => e.aroma).reduce((a, b) => a + b) / list.length).round(),
        finish: (list.map((e) => e.finish).reduce((a, b) => a + b) / list.length).round(),
        kick: (list.map((e) => e.kick).reduce((a, b) => a + b) / list.length).round(),
      );
    }
    return tasteProfile;
  }
}
