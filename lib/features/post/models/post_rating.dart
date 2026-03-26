// TODO: クラス名コメント修正
// ============================================================
// 飲み会投稿データモデル
// ============================================================

class PostRating {
  final String fromNick;
  final String? fromUid;
  final String toNick;
  final String role; // "host" | "guest"
  final int stars;
  final String comment;

  const PostRating({
    required this.fromNick,
    this.fromUid,
    required this.toNick,
    required this.role,
    required this.stars,
    required this.comment,
  });

  factory PostRating.fromMap(Map<String, dynamic> m) => PostRating(
        fromNick: m['fromNick'] ?? '',
        fromUid: m['fromUid'] as String?,
        toNick: m['toNick'] ?? '',
        role: m['role'] ?? 'guest',
        stars: (m['stars'] ?? 0) as int,
        comment: m['comment'] ?? '',
      );
  Map<String, dynamic> toMap() => {
        'fromNick': fromNick,
        'fromUid': fromUid,
        'toNick': toNick,
        'role': role,
        'stars': stars,
        'comment': comment,
      };
}
