// ============================================================
// ブロック済みユーザー（未成年）データモデル
// ============================================================

class BlockedUser {
  final String uid;
  final String email;
  final String birthday;
  final String blockedAt;

  const BlockedUser({
    required this.uid,
    required this.email,
    required this.birthday,
    required this.blockedAt,
  });

  factory BlockedUser.fromMap(String uid, Map<String, dynamic> m) => BlockedUser(
        uid: uid,
        email: m['email'] ?? '',
        birthday: m['birthday'] ?? '',
        blockedAt: m['blockedAt'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'birthday': birthday,
        'blockedAt': blockedAt,
      };
}
