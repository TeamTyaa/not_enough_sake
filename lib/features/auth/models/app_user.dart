// ============================================================
// アプリユーザーモデル
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/models/taste_profile.dart';

class AppUser {
  final String uid;
  final String nickname;
  final String email;
  final Timestamp birthday;
  final String gender;
  final List<String> genres;
  final TasteProfile tasteProfile;
  final double? trustScore;
  final int trustCount;
  final Timestamp createdAt;
  final Timestamp updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        nickname: m['nickname'] ?? '',
        email: m['email'] ?? '',
        birthday: m['birthday'] ?? Timestamp.now(),
        gender: m['gender'] ?? '',
        genres: List<String>.from(m['genres'] ?? []),
        tasteProfile: TasteProfile.fromMap(
          (m['tasteProfile'] as Map<String, dynamic>?) ?? {},
        ),
        trustScore: (m['trustScore'] as num?)?.toDouble(),
        trustCount: (m['trustCount'] ?? 0) as int,
        createdAt: m['createdAt'] ?? Timestamp.now(),
        updatedAt: m['updatedAt'] ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nickname': nickname,
        'email': email,
        'birthday': birthday,
        'gender': gender,
        'genres': genres,
        'tasteProfile': tasteProfile.toMap(),
        'trustScore': trustScore,
        'trustCount': trustCount,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  bool get isOverTwentyYearsOld {
    final b = birthday.toDate();
    return DateTime.now().compareTo(DateTime(b.year + 20, b.month, b.day)) >= 0;
  }

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
        createdAt: createdAt,
        updatedAt: Timestamp.now(),
      );
}
