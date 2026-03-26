// ============================================================
// ユーザーデータモデル
// ============================================================

import '../../common/models/taste_profile.dart';

class AppUser {
  final String uid;
  final String nickname;
  final String email;
  final String birthday; // "YYYY-MM-DD"
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
        uid: uid,
        nickname: m['nickname'] ?? '',
        email: m['email'] ?? '',
        birthday: m['birthday'] ?? '',
        gender: m['gender'] ?? '',
        genres: List<String>.from(m['genres'] ?? []),
        tasteProfile: TasteProfile.fromMap(
          (m['tasteProfile'] as Map<String, dynamic>?) ?? {},
        ),
        trustScore: (m['trustScore'] as num?)?.toDouble(),
        trustCount: (m['trustCount'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'nickname': nickname,
        'email': email,
        'birthday': birthday,
        'gender': gender,
        'genres': genres,
        'tasteProfile': tasteProfile.toMap(),
        'trustScore': trustScore,
        'trustCount': trustCount,
      };

  AppUser copyWith({
    String? nickname,
    List<String>? genres,
    TasteProfile? tasteProfile,
    double? trustScore,
    int? trustCount,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        birthday: birthday,
        gender: gender,
        nickname: nickname ?? this.nickname,
        genres: genres ?? this.genres,
        tasteProfile: tasteProfile ?? this.tasteProfile,
        trustScore: trustScore ?? this.trustScore,
        trustCount: trustCount ?? this.trustCount,
      );
}
