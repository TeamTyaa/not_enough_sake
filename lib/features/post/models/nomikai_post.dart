// ============================================================
// 飲み会投稿モデル
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/models/taste_profile.dart';
import 'intent_user.dart';
import 'nomikai_rating.dart';
import 'post_status.dart';

class NomikaiPost {
  final String id;
  final String? title;
  final Timestamp date;
  final String place;
  final String? genre;
  final String budget;
  final int capacity;
  final int minAttendees;
  final String message;
  final String authorUid;
  final String authorNick;
  final TasteProfile authorTaste;
  final double authorTrust;
  final int authorTrustCount;
  final PostStatus status;
  final List<IntentUser> intents;
  final List<NomikaiRating> ratings;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const NomikaiPost({
    required this.id,
    this.title,
    required this.date,
    required this.place,
    this.genre,
    required this.budget,
    required this.capacity,
    required this.minAttendees,
    required this.message,
    required this.authorUid,
    required this.authorNick,
    required this.authorTaste,
    required this.authorTrust,
    this.authorTrustCount = 0,
    this.status = PostStatus.open,
    this.intents = const [],
    this.ratings = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory NomikaiPost.fromMap(String id, Map<String, dynamic> m) => NomikaiPost(
        id: id,
        title: m['title'] as String?,
        date: m['date'] ?? Timestamp.now(),
        place: m['place'] ?? '',
        genre: m['genre'] as String?,
        budget: m['budget'] ?? '',
        capacity: (m['capacity'] ?? 0) as int,
        minAttendees: (m['minAttendees'] ?? 0) as int,
        message: m['message'] ?? '',
        authorUid: m['authorUid'] ?? '',
        authorNick: m['authorNick'] ?? '',
        authorTaste: TasteProfile.fromMap(
          (m['authorTaste'] as Map<String, dynamic>?) ?? {},
        ),
        authorTrust: (m['authorTrust'] as num?)?.toDouble() ?? 0,
        authorTrustCount: (m['authorTrustCount'] ?? 0) as int,
        status: postStatusFromInt((m['status'] ?? 0) as int) ?? PostStatus.open,
        intents: (m['intents'] as List?)?.map((e) => IntentUser.fromMap(e as Map<String, dynamic>)).toList() ?? [],
        ratings: (m['ratings'] as List?)?.map((e) => NomikaiRating.fromMap(e as Map<String, dynamic>)).toList() ?? [],
        createdAt: m['createdAt'] ?? Timestamp.now(),
        updatedAt: m['updatedAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': date,
        'place': place,
        'genre': genre,
        'budget': budget,
        'capacity': capacity,
        'minAttendees': minAttendees,
        'message': message,
        'authorNick': authorNick,
        'authorUid': authorUid,
        'authorTaste': authorTaste.toMap(),
        'authorTrust': authorTrust,
        'authorTrustCount': authorTrustCount,
        'status': postStatusToInt(status),
        'intents': intents.map((e) => e.toMap()).toList(),
        'ratings': ratings.map((e) => e.toMap()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  NomikaiPost copyWith({
    PostStatus? status,
    List<IntentUser>? intents,
    List<NomikaiRating>? ratings,
  }) =>
      NomikaiPost(
        id: id,
        title: title,
        date: date,
        place: place,
        genre: genre,
        budget: budget,
        capacity: capacity,
        minAttendees: minAttendees,
        message: message,
        authorNick: authorNick,
        authorUid: authorUid,
        authorTaste: authorTaste,
        authorTrust: authorTrust,
        authorTrustCount: authorTrustCount,
        status: status ?? this.status,
        intents: intents ?? this.intents,
        ratings: ratings ?? this.ratings,
        createdAt: createdAt,
        updatedAt: Timestamp.now(),
      );
}
