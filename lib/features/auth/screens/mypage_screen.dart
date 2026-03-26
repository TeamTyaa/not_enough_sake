import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';
import '../../../widgets/cards/section_label.dart';
import '../../../widgets/inputs/genre_selector.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../token/providers/token_provider.dart';
import '../providers/auth_provider.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  late TextEditingController _nickCtrl;
  late List<String> _genres;
  bool _saving = false, _saved = false;
  String _err = '';
  String? _modal; // 'terms' | 'privacy' | 'delete'

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _nickCtrl = TextEditingController(text: user.nickname);
    _genres = List.from(user.genres);
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user!;
    if (_nickCtrl.text.trim().isEmpty || _genres.isEmpty) return;
    setState(() {
      _saving = true;
      _err = '';
    });
    try {
      await ref.read(authProvider.notifier).updateUser(
            user.copyWith(nickname: _nickCtrl.text.trim(), genres: _genres),
          );
      setState(() => _saved = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saved = false);
    } catch (e) {
      setState(() => _err = '保存に失敗しました');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final tokens = ref.watch(tokenProvider(user.uid));

    return Scaffold(
      appBar: nomigatariAppBar(title: 'マイページ', onBack: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('MY PAGE'),

          // プロフィール編集
          _Card(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _FL('プロフィール編集'),
            const _FL('ニックネーム'),
            TextField(controller: _nickCtrl, style: const TextStyle(color: kText), onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
            const _FL('紹介してほしいお酒のジャンル'),
            GenreSelector(selected: _genres, onChanged: (g) => setState(() => _genres = g)),
            if (_genres.isEmpty)
              const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('1つ以上選んでください', style: TextStyle(fontSize: 11, color: kRed))),
            const SizedBox(height: 16),
            if (_err.isNotEmpty) ...[
              Text(_err, style: const TextStyle(fontSize: 11, color: kRed)),
              const SizedBox(height: 8),
            ],
            Row(children: [
              GoldButton(
                  label: '変更を保存',
                  loading: _saving,
                  onPressed: _nickCtrl.text.trim().isNotEmpty && _genres.isNotEmpty ? _save : null),
              if (_saved) ...[
                const SizedBox(width: 14),
                const Text('✓ 保存しました', style: TextStyle(fontSize: 11, color: kGreen)),
              ],
            ]),
          ])),
          const SizedBox(height: 14),

          // トークン・課金
          _Card(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _FL('トークン・課金'),
            Row(children: [
              _TokenDisplay(tokens.free, '合', kGold),
              const SizedBox(width: 24),
              _TokenDisplay(tokens.paid, '升', Color(0xFFc07a5a)),
            ]),
            const SizedBox(height: 14),
            const Text('レビュー1本につき1合もらえます。', style: TextStyle(fontSize: 11, color: kDim, height: 1.7)),
            const SizedBox(height: 16),
            const _FL('有料トークンを購入'),
            ...kTokenPlans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan.label, style: const TextStyle(fontSize: 14, color: kText)),
                      Text(plan.desc, style: const TextStyle(fontSize: 11, color: Color(0xFFc07a5a))),
                    ]),
                    GoldButton(
                      label: '購入',
                      small: true,
                      onPressed: () async {
                        // TODO: Stripe決済実装
                        final messenger = ScaffoldMessenger.of(context);

                        await ref.read(tokenProvider(user.uid).notifier).addPaid(plan.paid);
                        messenger.showSnackBar(SnackBar(content: Text('${plan.desc}を購入しました！')));
                      },
                    ),
                  ]),
                )),
            const Text('※ 購入はStripe決済で処理されます（実装予定）。', style: TextStyle(fontSize: 10, color: Color(0xFF3a3028))),
          ])),
          const SizedBox(height: 14),

          // アカウント情報
          _Card(
              child: Column(children: [
            _InfoRow('メールアドレス', user.email),
            _InfoRow('生年月日', user.birthday),
            _InfoRow('性別', user.gender),
          ])),
          const SizedBox(height: 14),

          // 法的情報
          _Card(
              child: Column(children: [
            _MenuRow('利用規約', () => setState(() => _modal = 'terms')),
            _MenuRow('プライバシーポリシー', () => setState(() => _modal = 'privacy')),
          ])),
          const SizedBox(height: 14),

          // アクション
          _Card(
              child: Wrap(spacing: 12, runSpacing: 8, children: [
            GoldButton(label: 'ログアウト', outline: true, onPressed: () => ref.read(authProvider.notifier).signOut()),
            GoldButton(
                label: 'アカウントを削除する', outline: true, danger: true, onPressed: () => setState(() => _modal = 'delete')),
          ])),
          const SizedBox(height: 40),
        ],
      ),

      // モーダル
      floatingActionButton: _modal != null ? _buildModal(user.uid) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModal(String uid) {
    if (_modal == 'terms' || _modal == 'privacy') {
      final isTerms = _modal == 'terms';
      return _ModalSheet(
        title: isTerms ? '利用規約' : 'プライバシーポリシー',
        content: isTerms ? _kTerms : _kPrivacy,
        onClose: () => setState(() => _modal = null),
      );
    }
    if (_modal == 'delete') {
      return _ConfirmSheet(
        message: 'すべてのデータが削除されます。この操作は取り消せません。',
        onConfirm: () => ref.read(authProvider.notifier).deleteAccount(uid),
        onCancel: () => setState(() => _modal = null),
      );
    }
    return const SizedBox.shrink();
  }
}

class _TokenDisplay extends StatelessWidget {
  final int value;
  final String unit;
  final Color color;
  const _TokenDisplay(this.value, this.unit, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text('$value', style: TextStyle(fontSize: 32, color: color, fontStyle: FontStyle.italic)),
        Text(unit, style: const TextStyle(fontSize: 10, color: kDim, letterSpacing: 1)),
      ]);
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(3),
        ),
        child: child,
      );
}

class _FL extends StatelessWidget {
  final String text;
  const _FL(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 9, letterSpacing: 2, color: kDim)),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kDim)),
          Text(value, style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      );
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuRow(this.label, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 13, color: kMuted)),
            const Icon(Icons.arrow_forward_ios, size: 14, color: kDim),
          ]),
        ),
      );
}

class _ModalSheet extends StatelessWidget {
  final String title, content;
  final VoidCallback onClose;
  const _ModalSheet({required this.title, required this.content, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration:
            BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(8)),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontSize: 15, color: kText)),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: kDim, size: 20)),
          ]),
          const Divider(color: kBorder),
          Expanded(
              child: SingleChildScrollView(
            child: Text(content, style: const TextStyle(fontSize: 12, color: kMuted, height: 1.85)),
          )),
          const SizedBox(height: 12),
          GoldButton(label: '閉じる', small: true, onPressed: onClose),
        ]),
      );
}

class _ConfirmSheet extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm, onCancel;
  const _ConfirmSheet({required this.message, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: kCard, border: Border.all(color: const Color(0xFF5a2020)), borderRadius: BorderRadius.circular(8)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('アカウントを削除しますか？', style: TextStyle(fontSize: 15, color: kText)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(fontSize: 12, color: kMuted, height: 1.8)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GoldButton(label: '削除する', danger: true, onPressed: onConfirm)),
            const SizedBox(width: 12),
            Expanded(child: GoldButton(label: 'キャンセル', outline: true, onPressed: onCancel)),
          ]),
        ]),
      );
}

const _kTerms = '''【利用規約（仮）】
本サービス「酒語りＮ」は、お酒の好みに基づいたレコメンドおよびコミュニティ機能を提供します。
・20歳未満の方はご利用いただけません。
・投稿内容は他のユーザーに公開される場合があります。
・虚偽の情報登録、他ユーザーへの嫌がらせは禁止します。
・運営はサービスの内容を予告なく変更・終了する場合があります。
※本規約は正式リリース時に改訂されます。''';

const _kPrivacy = '''【プライバシーポリシー（仮）】
取得する情報：Googleアカウントの表示名・メールアドレス、登録情報（ニックネーム・生年月日・性別）、レビュー・お気に入りデータ、飲み会投稿内容。
利用目的：お酒のレコメンド精度の向上、好み類似ユーザーとのマッチング、サービス改善。
第三者提供：法令に基づく場合を除き、ユーザーの同意なく第三者に提供しません。
データ削除：アカウント削除リクエストにより、保有データを削除します。
※正式リリース時に改訂されます。''';
