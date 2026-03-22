// ============================================================
// models.dart — 呑み語りN 全データモデル
// ============================================================

// ── 好みスライダー値 ────────────────────────────────────────
class TasteProfile {
  final int sweet;  // -5(甘い) ～ +5(辛い)
  final int body;   // -5(軽い) ～ +5(濃厚)
  final int aroma;  // -5(フルーティ) ～ +5(どっしり)
  final int finish; // -5(すっきり) ～ +5(コク残る)
  final int kick;   // -5(まろやか) ～ +5(キリッと)

  const TasteProfile({
    this.sweet = 0, this.body = 0, this.aroma = 0,
    this.finish = 0, this.kick = 0,
  });

  factory TasteProfile.fromMap(Map<String, dynamic> m) => TasteProfile(
    sweet:  (m['sweet']  ?? 0) as int,
    body:   (m['body']   ?? 0) as int,
    aroma:  (m['aroma']  ?? 0) as int,
    finish: (m['finish'] ?? 0) as int,
    kick:   (m['kick']   ?? 0) as int,
  );

  Map<String, dynamic> toMap() => {
    'sweet': sweet, 'body': body, 'aroma': aroma,
    'finish': finish, 'kick': kick,
  };

  bool get isJustRight =>
    sweet.abs() <= 1 && body.abs() <= 1 && aroma.abs() <= 1 &&
    finish.abs() <= 1 && kick.abs() <= 1;

  double distanceTo(TasteProfile other) {
    final ds = sweet  - other.sweet;
    final db = body   - other.body;
    final da = aroma  - other.aroma;
    final df = finish - other.finish;
    final dk = kick   - other.kick;
    return (ds*ds + db*db + da*da + df*df + dk*dk).toDouble().abs();
    // Use sqrt for actual distance: import 'dart:math'; sqrt(...)
  }

  static TasteProfile average(List<TasteProfile> list) {
    if (list.isEmpty) return const TasteProfile();
    return TasteProfile(
      sweet:  (list.map((e) => e.sweet).reduce((a,b)=>a+b) / list.length).round(),
      body:   (list.map((e) => e.body).reduce((a,b)=>a+b)  / list.length).round(),
      aroma:  (list.map((e) => e.aroma).reduce((a,b)=>a+b) / list.length).round(),
      finish: (list.map((e) => e.finish).reduce((a,b)=>a+b)/ list.length).round(),
      kick:   (list.map((e) => e.kick).reduce((a,b)=>a+b)  / list.length).round(),
    );
  }
}

// ── ユーザー ────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String nickname;
  final String email;
  final String birthday;   // "YYYY-MM-DD"
  final String gender;
  final List<String> genres;
  final TasteProfile tasteProfile;
  final double? trustScore;
  final int trustCount;

  const AppUser({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.birthday,
    required this.gender,
    required this.genres,
    required this.tasteProfile,
    this.trustScore,
    this.trustCount = 0,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
    uid:          uid,
    nickname:     m['nickname']  ?? '',
    email:        m['email']     ?? '',
    birthday:     m['birthday']  ?? '',
    gender:       m['gender']    ?? '',
    genres:       List<String>.from(m['genres'] ?? []),
    tasteProfile: TasteProfile.fromMap(
      (m['tasteProfile'] as Map<String, dynamic>?) ?? {},
    ),
    trustScore:  (m['trustScore'] as num?)?.toDouble(),
    trustCount:  (m['trustCount'] ?? 0) as int,
  );

  Map<String, dynamic> toMap() => {
    'nickname': nickname, 'email': email, 'birthday': birthday,
    'gender': gender, 'genres': genres,
    'tasteProfile': tasteProfile.toMap(),
    'trustScore': trustScore, 'trustCount': trustCount,
  };

  AppUser copyWith({
    String? nickname, List<String>? genres, TasteProfile? tasteProfile,
    double? trustScore, int? trustCount,
  }) => AppUser(
    uid: uid, email: email, birthday: birthday, gender: gender,
    nickname:     nickname     ?? this.nickname,
    genres:       genres       ?? this.genres,
    tasteProfile: tasteProfile ?? this.tasteProfile,
    trustScore:   trustScore   ?? this.trustScore,
    trustCount:   trustCount   ?? this.trustCount,
  );
}

// ── ブロック済みユーザー（未成年） ──────────────────────────
class BlockedUser {
  final String uid;
  final String email;
  final String birthday;
  final String blockedAt;

  const BlockedUser({
    required this.uid, required this.email,
    required this.birthday, required this.blockedAt,
  });

  factory BlockedUser.fromMap(String uid, Map<String, dynamic> m) => BlockedUser(
    uid: uid, email: m['email']??'',
    birthday: m['birthday']??'', blockedAt: m['blockedAt']??'',
  );

  Map<String, dynamic> toMap() => {
    'email': email, 'birthday': birthday, 'blockedAt': blockedAt,
  };
}

// ── お酒レビュー ────────────────────────────────────────────
class DrinkReview {
  final String id;
  final String name;
  final String category;
  final String tier;       // "low" | "mid" | "high" | "extra"
  final TasteProfile sliders;
  final String text;
  final bool justRight;
  final String date;       // "YYYY/MM/DD"
  final String? officialUrl;

  const DrinkReview({
    required this.id, required this.name, required this.category,
    required this.tier, required this.sliders, required this.text,
    required this.justRight, required this.date, this.officialUrl,
  });

  factory DrinkReview.fromMap(String id, Map<String, dynamic> m) => DrinkReview(
    id:          id,
    name:        m['name']     ?? '',
    category:    m['category'] ?? '',
    tier:        m['tier']     ?? '',
    sliders:     TasteProfile.fromMap(
      (m['sliders'] as Map<String, dynamic>?) ?? {},
    ),
    text:        m['text']      ?? '',
    justRight:   m['justRight'] ?? false,
    date:        m['date']      ?? '',
    officialUrl: m['officialUrl'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'category': category, 'tier': tier,
    'sliders': sliders.toMap(), 'text': text,
    'justRight': justRight, 'date': date, 'officialUrl': officialUrl,
  };
}

// ── お気に入り ──────────────────────────────────────────────
class FavoriteItem {
  final String id;
  final String name;
  final String category;

  const FavoriteItem({required this.id, required this.name, required this.category});

  factory FavoriteItem.fromMap(Map<String, dynamic> m) => FavoriteItem(
    id: m['id']??'', name: m['name']??'', category: m['category']??'',
  );
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'category': category};
}

// ── おすすめお酒 ────────────────────────────────────────────
class RecommendedDrink {
  final String name;
  final String category;
  final String description;
  final String? profile;
  final String? occasion;
  final String? officialUrl;
  final String priceKey; // "low" | "mid" | "high"

  const RecommendedDrink({
    required this.name, required this.category, required this.description,
    this.profile, this.occasion, this.officialUrl, required this.priceKey,
  });

  factory RecommendedDrink.fromMap(Map<String, dynamic> m, String priceKey) =>
    RecommendedDrink(
      name:        m['name']        ?? '',
      category:    m['category']    ?? '',
      description: m['description'] ?? '',
      profile:     m['profile']     as String?,
      occasion:    m['occasion']    as String?,
      officialUrl: m['officialUrl'] as String?,
      priceKey:    priceKey,
    );
}

// ── トークン ────────────────────────────────────────────────
class TokenBalance {
  final int free;  // 合
  final int paid;  // 升

  const TokenBalance({this.free = 0, this.paid = 0});

  factory TokenBalance.fromMap(Map<String, dynamic> m) => TokenBalance(
    free: (m['free'] ?? 0) as int,
    paid: (m['paid'] ?? 0) as int,
  );
  Map<String, dynamic> toMap() => {'free': free, 'paid': paid};

  TokenBalance copyWith({int? free, int? paid}) =>
    TokenBalance(free: free ?? this.free, paid: paid ?? this.paid);
}

// ── 飲み会投稿 ──────────────────────────────────────────────
enum PostStatus { open, confirmed, done, cancelled }

PostStatus postStatusFromString(String s) {
  switch (s) {
    case 'confirmed': return PostStatus.confirmed;
    case 'done':      return PostStatus.done;
    case 'cancelled': return PostStatus.cancelled;
    default:          return PostStatus.open;
  }
}

String postStatusToString(PostStatus s) {
  switch (s) {
    case PostStatus.confirmed: return 'confirmed';
    case PostStatus.done:      return 'done';
    case PostStatus.cancelled: return 'cancelled';
    default:                   return 'open';
  }
}

class IntentUser {
  final String uid;
  final String nick;
  const IntentUser({required this.uid, required this.nick});
  factory IntentUser.fromMap(Map<String, dynamic> m) =>
    IntentUser(uid: m['uid']??'', nick: m['nick']??'');
  Map<String, dynamic> toMap() => {'uid': uid, 'nick': nick};
}

class PostRating {
  final String fromNick;
  final String? fromUid;
  final String toNick;
  final String role;   // "host" | "guest"
  final int stars;
  final String comment;

  const PostRating({
    required this.fromNick, this.fromUid, required this.toNick,
    required this.role, required this.stars, required this.comment,
  });

  factory PostRating.fromMap(Map<String, dynamic> m) => PostRating(
    fromNick: m['fromNick']??'', fromUid: m['fromUid'] as String?,
    toNick: m['toNick']??'', role: m['role']??'guest',
    stars: (m['stars']??0) as int, comment: m['comment']??'',
  );
  Map<String, dynamic> toMap() => {
    'fromNick': fromNick, 'fromUid': fromUid, 'toNick': toNick,
    'role': role, 'stars': stars, 'comment': comment,
  };
}

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
    required this.id, this.title, required this.date, required this.place,
    this.genre, required this.budget, required this.capacity,
    required this.minAttendees, required this.message,
    required this.authorNick, this.authorUid, this.authorTaste,
    this.authorTrust, this.authorTrustCount = 0,
    this.status = PostStatus.open,
    this.intents = const [], this.ratings = const [],
  });

  factory NomikaiPost.fromMap(String id, Map<String, dynamic> m) => NomikaiPost(
    id:              id,
    title:           m['title'] as String?,
    date:            m['date']  ?? '',
    place:           m['place'] ?? '',
    genre:           m['genre'] as String?,
    budget:          m['budget'] ?? '',
    capacity:        (m['capacity']     ?? 0) as int,
    minAttendees:    (m['minAttendees'] ?? 0) as int,
    message:         m['message'] ?? '',
    authorNick:      m['authorNick'] ?? '',
    authorUid:       m['authorUid'] as String?,
    authorTaste:     m['authorTaste'] != null
      ? TasteProfile.fromMap(m['authorTaste'] as Map<String, dynamic>)
      : null,
    authorTrust:     (m['authorTrust'] as num?)?.toDouble(),
    authorTrustCount:(m['authorTrustCount'] ?? 0) as int,
    status:          postStatusFromString(m['status'] ?? 'open'),
    intents:         (m['intents'] as List?)
      ?.map((e) => IntentUser.fromMap(e as Map<String, dynamic>)).toList() ?? [],
    ratings:         (m['ratings'] as List?)
      ?.map((e) => PostRating.fromMap(e as Map<String, dynamic>)).toList() ?? [],
  );

  Map<String, dynamic> toMap() => {
    'title': title, 'date': date, 'place': place, 'genre': genre,
    'budget': budget, 'capacity': capacity, 'minAttendees': minAttendees,
    'message': message, 'authorNick': authorNick, 'authorUid': authorUid,
    'authorTaste': authorTaste?.toMap(), 'authorTrust': authorTrust,
    'authorTrustCount': authorTrustCount,
    'status': postStatusToString(status),
    'intents': intents.map((e) => e.toMap()).toList(),
    'ratings': ratings.map((e) => e.toMap()).toList(),
  };

  NomikaiPost copyWith({
    PostStatus? status, List<IntentUser>? intents, List<PostRating>? ratings,
  }) => NomikaiPost(
    id: id, title: title, date: date, place: place, genre: genre,
    budget: budget, capacity: capacity, minAttendees: minAttendees,
    message: message, authorNick: authorNick, authorUid: authorUid,
    authorTaste: authorTaste, authorTrust: authorTrust,
    authorTrustCount: authorTrustCount,
    status:  status  ?? this.status,
    intents: intents ?? this.intents,
    ratings: ratings ?? this.ratings,
  );
}

// ── 投稿コメント ────────────────────────────────────────────
class PostComment {
  final String id;
  final String nick;
  final String uid;
  final String text;
  final String createdAt; // ISO8601

  const PostComment({
    required this.id, required this.nick, required this.uid,
    required this.text, required this.createdAt,
  });

  factory PostComment.fromMap(String id, Map<String, dynamic> m) => PostComment(
    id: id, nick: m['nick']??'', uid: m['uid']??'',
    text: m['text']??'', createdAt: m['createdAt']??'',
  );
  Map<String, dynamic> toMap() => {
    'nick': nick, 'uid': uid, 'text': text, 'createdAt': createdAt,
  };
}

// ── お知らせ ────────────────────────────────────────────────
class AppNotice {
  final String id;
  final String title;
  final String body;
  final String startAt;  // "YYYY-MM-DD"
  final String endAt;    // "YYYY-MM-DD"
  final String createdAt;

  const AppNotice({
    required this.id, required this.title, required this.body,
    required this.startAt, required this.endAt, required this.createdAt,
  });

  factory AppNotice.fromMap(String id, Map<String, dynamic> m) => AppNotice(
    id: id, title: m['title']??'', body: m['body']??'',
    startAt: m['startAt']??'', endAt: m['endAt']??'', createdAt: m['createdAt']??'',
  );

  bool isActive(DateTime today) {
    final s = DateTime.tryParse(startAt);
    final e = DateTime.tryParse(endAt);
    if (s == null || e == null) return false;
    return !today.isBefore(s) && !today.isAfter(e);
  }
}

// ── 通報 ────────────────────────────────────────────────────
class ReportData {
  final String postId;
  final String authorNick;
  final String reporterUid;
  final String reporterNick;
  final String reason;
  final String detail;
  final String reportedAt;

  const ReportData({
    required this.postId, required this.authorNick,
    required this.reporterUid, required this.reporterNick,
    required this.reason, required this.detail, required this.reportedAt,
  });

  Map<String, dynamic> toMap() => {
    'postId': postId, 'authorNick': authorNick,
    'reporterUid': reporterUid, 'reporterNick': reporterNick,
    'reason': reason, 'detail': detail, 'reportedAt': reportedAt,
  };
}
