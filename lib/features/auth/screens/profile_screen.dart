// ============================================================
// プロフィール登録画面
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';
import '../../../widgets/cards/section_label.dart';
import '../../../widgets/inputs/genre_selector.dart';
import '../../../widgets/inputs/simple_slider.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../common/models/taste_profile.dart';
import '../models/app_user.dart';
import '../models/blocked_user.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  final String? displayName;
  final String? email;
  const ProfileScreen({
    super.key,
    required this.uid,
    this.displayName,
    this.email,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nickCtrl = TextEditingController();
  String _dob = '';
  String _gender = '';
  List<String> _genres = [];
  TasteProfile _sliders = const TasteProfile();
  String _err = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nickCtrl.text = widget.displayName ?? '';
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nickCtrl.text.trim().isEmpty || _dob.isEmpty || _gender.isEmpty || _genres.isEmpty) {
      setState(() => _err = 'すべての項目を入力してください');
      return;
    }

    // 年齢チェック
    final birthday = DateTime.tryParse(_dob);
    if (birthday == null) {
      setState(() => _err = '生年月日が正しくありません');
      return;
    }
    final age = DateTime.now().difference(birthday).inDays / 365.25;
    if (age < 20) {
      // 未成年ブロック
      setState(() => _loading = true);
      try {
        final blocked = BlockedUser(
          uid: widget.uid,
          isUnderAge: true,
          isBanned: false,
          reason: '未成年のため',
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );
        await ref.read(authProvider.notifier).saveProfile(
              AppUser(
                uid: widget.uid,
                nickname: _nickCtrl.text.trim(),
                email: widget.email ?? '',
                birthday: Timestamp.fromDate(birthday),
                gender: _gender,
                genres: _genres,
                tasteProfile: _sliders,
                createdAt: Timestamp.now(),
                updatedAt: Timestamp.now(),
              ),
            );
        await ref.read(authProvider.notifier).saveBlocked(blocked);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    setState(() {
      _loading = true;
      _err = '';
    });
    try {
      final user = AppUser(
        uid: widget.uid,
        nickname: _nickCtrl.text.trim(),
        email: widget.email ?? '',
        birthday: Timestamp.fromDate(birthday),
        gender: _gender,
        genres: _genres,
        tasteProfile: _sliders,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      await ref.read(authProvider.notifier).saveProfile(user);
    } catch (e) {
      setState(() => _err = '保存に失敗しました。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = _nickCtrl.text.trim().isNotEmpty && _dob.isNotEmpty && _gender.isNotEmpty && _genres.isNotEmpty;
    return Scaffold(
      appBar: nomigatariAppBar(title: 'プロフィール登録', showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel('PROFILE SETUP'),
          const Text('お酒を楽しむための情報を教えてください。', style: TextStyle(fontSize: 13, color: kMuted, height: 1.75)),
          const SizedBox(height: 24),

          // ニックネーム
          _FieldLabel('ニックネーム（Googleの表示名から取得）'),
          TextField(
            controller: _nickCtrl,
            style: const TextStyle(color: kText),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '例：みやび'),
          ),
          const SizedBox(height: 18),

          // 生年月日
          _FieldLabel('生年月日（年齢確認に使用）'),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now.subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime(1900),
                lastDate: now,
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: kGold),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _dob = picked.toIso8601String().split('T').first);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF080604),
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                _dob.isEmpty ? '日付を選択' : _dob,
                style: TextStyle(
                  fontSize: 13,
                  color: _dob.isEmpty ? kDim : kText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 性別
          _FieldLabel('性別'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['男性', '女性', 'その他', '無回答'].map((g) {
              final on = _gender == g;
              return GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: on ? kGold : const Color(0xFF2a2420)),
                    color: on ? kGold.withValues(alpha: 0.12) : Colors.transparent,
                  ),
                  child: Text(g, style: TextStyle(fontSize: 11, color: on ? kGold : kDim)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // ジャンル
          _FieldLabel('紹介してほしいお酒のジャンル（複数選択可）'),
          GenreSelector(
            selected: _genres,
            onChanged: (g) => setState(() => _genres = g),
          ),
          if (_genres.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('1つ以上選んでください', style: TextStyle(fontSize: 11, color: kRed)),
            ),
          const SizedBox(height: 24),

          // スライダー
          _FieldLabel('好みの味わい（飲み会マッチングに使用）'),
          const Text('直感で動かしてください。わからなければ中央のままでOKです。', style: TextStyle(fontSize: 11, color: Color(0xFF3a3028))),
          const SizedBox(height: 14),
          ...kAxes.map((ax) => SimpleSlider(
                axis: ax,
                value: _getAxisValue(ax.key),
                onChanged: (v) => setState(() => _sliders = _setAxisValue(ax.key, v)),
              )),

          if (_err.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_err, style: const TextStyle(fontSize: 12, color: kRed)),
          ],
          const SizedBox(height: 16),

          GoldButton(
            label: '登録してはじめる →',
            loading: _loading,
            onPressed: valid ? _save : null,
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  int _getAxisValue(String key) {
    switch (key) {
      case 'sweet':
        return _sliders.sweet;
      case 'body':
        return _sliders.body;
      case 'aroma':
        return _sliders.aroma;
      case 'finish':
        return _sliders.finish;
      case 'kick':
        return _sliders.kick;
      default:
        return 0;
    }
  }

  TasteProfile _setAxisValue(String key, int v) {
    return TasteProfile(
      sweet: key == 'sweet' ? v : _sliders.sweet,
      body: key == 'body' ? v : _sliders.body,
      aroma: key == 'aroma' ? v : _sliders.aroma,
      finish: key == 'finish' ? v : _sliders.finish,
      kick: key == 'kick' ? v : _sliders.kick,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 2,
              color: kDim,
            )),
      );
}
