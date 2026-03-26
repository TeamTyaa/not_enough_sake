// ============================================================
// 飲み会投稿データモデル
// ============================================================

import '../../common/models/taste_profile.dart';
import 'intent_user.dart';
import 'post_rating.dart';
import 'post_status.dart';

class NomikaiPost {
  final String id;
  final String? title;
  final String date;
  final String place;
  final String? genre;
  final String budget;
  final int capacity;
  final int minAttendees;
  final String message;
  final String authorNick;
  final String? authorUid;
  final TasteProfile? authorTaste;
  final double? authorTrust;
  final int authorTrustCount;
  final PostStatus status;
  final List<IntentUser> intents;
  final List<PostRating> ratings;

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
    required this.authorNick,
    this.authorUid,
    this.authorTaste,
    this.authorTrust,
    this.authorTrustCount = 0,
    this.status = PostStatus.open,
    this.intents = const [],
    this.ratings = const [],
  });

  factory NomikaiPost.fromMap(String id, Map<String, dynamic> m) => NomikaiPost(
        id: id,
        title: m['title'] as String?,
        date: m['date'] ?? '',
        place: m['place'] ?? '',
        genre: m['genre'] as String?,
        budget: m['budget'] ?? '',
        capacity: (m['capacity'] ?? 0) as int,
        minAttendees: (m['minAttendees'] ?? 0) as int,
        message: m['message'] ?? '',
        authorNick: m['authorNick'] ?? '',
        authorUid: m['authorUid'] as String?,
        authorTaste: m['authorTaste'] != null ? TasteProfile.fromMap(m['authorTaste'] as Map<String, dynamic>) : null,
        authorTrust: (m['authorTrust'] as num?)?.toDouble(),
        authorTrustCount: (m['authorTrustCount'] ?? 0) as int,
        status: postStatusFromString(m['status'] ?? 'open'),
        intents: (m['intents'] as List?)?.map((e) => IntentUser.fromMap(e as Map<String, dynamic>)).toList() ?? [],
        ratings: (m['ratings'] as List?)?.map((e) => PostRating.fromMap(e as Map<String, dynamic>)).toList() ?? [],
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
        'authorTaste': authorTaste?.toMap(),
        'authorTrust': authorTrust,
        'authorTrustCount': authorTrustCount,
        'status': postStatusToString(status),
        'intents': intents.map((e) => e.toMap()).toList(),
        'ratings': ratings.map((e) => e.toMap()).toList(),
      };

  NomikaiPost copyWith({
    PostStatus? status,
    List<IntentUser>? intents,
    List<PostRating>? ratings,
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
      );
}
