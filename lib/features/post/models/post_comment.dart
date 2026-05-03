// ============================================================
// 投稿コメントモデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String nick;
  final String uid;
  final String text;
  final Timestamp createdAt;

  const PostComment({
    required this.id,
    required this.nick,
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  factory PostComment.fromMap(String id, Map<String, dynamic> m) => PostComment(
        id: id,
        nick: m['nick'] ?? '',
        uid: m['uid'] ?? '',
        text: m['text'] ?? '',
        createdAt: m['createdAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'nick': nick,
        'uid': uid,
        'text': text,
        'createdAt': createdAt,
      };
}
