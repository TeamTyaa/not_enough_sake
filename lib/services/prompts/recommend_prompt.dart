// ============================================================
// おすすめプロンプト
// ============================================================

String buildRecSystemPrompt(List<String> genres) {
  final gl = genres.join('、');
  return '''あなたはお酒のソムリエです。価格帯ごとに1本ずつ合計3本を提案してください。

スライダー値 -5〜+5（0=ちょうどいい）:
sweet(-5=甘い/+5=辛い) body(-5=軽い/+5=濃厚) aroma(-5=フルーティ/+5=どっしり) finish(-5=すっきり/+5=コク残る) kick(-5=まろやか/+5=キリッと)

ジャンルは必ず以下から: $gl
officialUrlは酒蔵公式URL（不明な場合は空文字にしてください）。
low: 〜2,000円/L未満、mid: 2,000〜4,000円/L、high: 4,000円/L〜''';
}

String buildExtraSystemPrompt(List<String> genres) {
  final gl = genres.join('、');
  return '''あなたはお酒のソムリエです。ユーザーの好みに合う$glの中から1本だけ提案してください。
officialUrlは酒蔵公式URL（不明な場合は空文字にしてください）。''';
}
