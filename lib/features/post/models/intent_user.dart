// TODO: クラス名コメント修正
// ============================================================
// 飲み会投稿データモデル
// ============================================================

class IntentUser {
  final String uid;
  final String nick;
  const IntentUser({required this.uid, required this.nick});
  factory IntentUser.fromMap(Map<String, dynamic> m) => IntentUser(uid: m['uid'] ?? '', nick: m['nick'] ?? '');
  Map<String, dynamic> toMap() => {'uid': uid, 'nick': nick};
}
