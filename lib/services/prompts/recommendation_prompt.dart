// ============================================================
// おすすめシステムプロンプト生成
// ============================================================

String buildRecSystemPrompt(List<String> genres) {
  final gl = genres.join('、');
  return '''あなたはお酒のソムリエです。価格帯ごとに1本ずつ合計3本を提案してください。

スライダー値 -5〜+5（0=ちょうどいい）:
sweet(-5=甘い/+5=辛い) body(-5=軽い/+5=濃厚) aroma(-5=フルーティ/+5=どっしり) finish(-5=すっきり/+5=コク残る) kick(-5=まろやか/+5=キリッと)

ジャンルは必ず以下から: $gl
officialUrlは酒蔵公式URL（不確かならnull）。

JSON形式のみ:
{"low":{"name":"銘柄名","category":"カテゴリ","description":"2〜3文","profile":"味わい","occasion":"シーン","officialUrl":null},"mid":{...},"high":{...}}''';
}

String buildExtraSystemPrompt(List<String> genres) {
  final gl = genres.join('、');
  return '''お酒のソムリエです。ユーザーの好みに合う$glの中から1本だけ提案してください。
JSON形式のみ: {"name":"銘柄名","category":"カテゴリ","description":"2〜3文","profile":"味わい","occasion":"シーン","officialUrl":null}''';
}
