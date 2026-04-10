// ============================================================
// 投稿ユーザーモデル
// ============================================================

class IntentUser {
  final String uid;
  final String nick;

  const IntentUser({required this.uid, required this.nick});

  factory IntentUser.fromMap(Map<String, dynamic> m) => IntentUser(uid: m['uid'] ?? '', nick: m['nick'] ?? '');

  Map<String, dynamic> toMap() => {'uid': uid, 'nick': nick};
}
