// ============================================================
// 掲示板投稿画面
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';
import '../../../widgets/cards/category_tag.dart';
import '../../../widgets/cards/section_label.dart';
import '../../../widgets/cards/trust_badge.dart';
import '../../../widgets/feedback/error_banner.dart';
import '../../../widgets/inputs/star_input.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../auth/screens/user_profile_screen.dart';
import '../../common/models/taste_profile.dart';
import '../models/intent_user.dart';
import '../models/nomikai_post.dart';
import '../models/nomikai_rating.dart';
import '../models/post_comment.dart';
import '../models/post_status.dart';
import '../models/report.dart';
import '../providers/posts_provider.dart';
import '../repositories/post_repository.dart';
import '../repositories/report_repository.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final NomikaiPost post;
  final String myNick, myUid;
  final TasteProfile myTaste;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.myNick,
    required this.myUid,
    required this.myTaste,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late NomikaiPost _post;
  List<PostComment> _comments = [];
  bool _loadingComments = true;
  final _commentCtrl = TextEditingController();
  final _postRepository = PostRepository();
  final _reportRepository = ReportRepository();
  bool _submitting = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _loadComments() async {
    final comments = await _postRepository.getComments(_post.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    }
  }

  bool get _hasIntent => _post.intents.any((i) => i.nick == widget.myNick);
  bool get _isAuthor => _post.authorNick == widget.myNick;
  bool get _isDone => _post.status == PostStatus.done;
  bool get _alreadyRated => _post.ratings.any((r) => r.fromNick == widget.myNick);
  bool get _canRate => _isDone && (_isAuthor || _hasIntent) && !_alreadyRated;

  static const statusColor = {
    PostStatus.open: Color(0xFF7aaa6a),
    PostStatus.confirmed: kGold,
    PostStatus.done: kMuted,
    PostStatus.cancelled: Color(0xFF8a4040),
  };
  static const statusLabel = {
    PostStatus.open: '参加者募集中',
    PostStatus.confirmed: '開催決定！',
    PostStatus.done: '開催済み',
    PostStatus.cancelled: 'キャンセル',
  };

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() {
      _submitting = true;
      _err = '';
    });
    try {
      final c = PostComment(
        id: '',
        nick: widget.myNick,
        uid: widget.myUid,
        text: _commentCtrl.text.trim(),
        createdAt: Timestamp.now(),
      );
      await _postRepository.addComment(_post.id, c);
      setState(() {
        _comments = [..._comments, PostComment.fromMap(c.toMap())];
        _commentCtrl.clear();
      });
    } catch (e) {
      setState(() => _err = 'コメントの投稿に失敗しました');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addIntent() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newIntents = [..._post.intents, IntentUser(uid: widget.myUid, nick: widget.myNick)];
      final newStatus = newIntents.length >= _post.minAttendees && _post.status == PostStatus.open
          ? PostStatus.confirmed
          : _post.status;
      final updated = _post.copyWith(intents: newIntents, status: newStatus);
      await _postRepository.updatePost(updated);
      ref.read(postsProvider.notifier).updatePost(updated);
      setState(() => _post = updated);
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('参加意志の登録に失敗しました')));
    }
  }

  Future<void> _cancelIntent() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newIntents = _post.intents.where((i) => i.uid != widget.myUid).toList();
      final updated = _post.copyWith(intents: newIntents);
      await _postRepository.updatePost(updated);
      ref.read(postsProvider.notifier).updatePost(updated);
      setState(() => _post = updated);
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('キャンセルに失敗しました')));
    }
  }

  void _navigateToUser(String nick, String? uid) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UserProfileScreen(nick: nick, uid: uid ?? nick),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: nomigatariAppBar(
          title: _post.title ?? '飲み会の詳細',
          subtitle: '● ${statusLabel[_post.status] ?? _post.status.name}',
          onBack: () => Navigator.of(context).pop(),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── 投稿情報 ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kCard,
                border:
                    Border.all(color: _post.status == PostStatus.confirmed ? kGold.withValues(alpha: 0.35) : kBorder),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_post.genre != null) ...[
                  CategoryTag(_post.genre!),
                  const SizedBox(height: 10),
                ],
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  GestureDetector(
                    onTap: () => _navigateToUser(_post.authorNick, _post.authorUid),
                    child: Text(_post.authorNick,
                        style: const TextStyle(
                          fontSize: 15,
                          color: kGold,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0x66c9a84c),
                        )),
                  ),
                  TrustBadge(score: _post.authorTrust, count: _post.authorTrustCount),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 16, runSpacing: 6, children: [
                  _IC('📅', DateFormat('yyyy年M月d日').format(_post.date.toDate())),
                  _IC('📍', _post.place),
                  _IC('💴', _post.budget),
                  _IC('👥', '${_post.intents.length}/${_post.capacity}人'),
                ]),
                const SizedBox(height: 8),
                Text('開催確定条件: 参加意志 ${_post.minAttendees}人以上', style: const TextStyle(fontSize: 12, color: kDim)),
                const SizedBox(height: 10),
                Text(_post.message, style: const TextStyle(fontSize: 13, color: kMuted, height: 1.85)),
                const SizedBox(height: 16),
                // アクション
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (!_isAuthor && _post.status == PostStatus.open && !_hasIntent)
                    GoldButton(label: '参加意志を登録する', small: true, onPressed: _addIntent),
                  if (!_isAuthor && _post.status == PostStatus.open && _hasIntent)
                    GoldButton(label: '参加意志をキャンセル', small: true, outline: true, danger: true, onPressed: _cancelIntent),
                  if (_canRate)
                    GoldButton(label: '評価を送る', small: true, outline: true, onPressed: () => _showRatingSheet()),
                  if (_alreadyRated) const Text('✓ 評価済み', style: TextStyle(fontSize: 10, color: kGreen)),
                  if (!_isAuthor)
                    TextButton(
                      onPressed: () => _showReportSheet(),
                      child: const Text('⚑ 通報', style: TextStyle(fontSize: 10, color: Color(0xFF5a3a3a))),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // ── 参加意志あり ──────────────────────────────────
            if (_post.intents.isNotEmpty) ...[
              SectionLabel('参加意志あり — ${_post.intents.length}人'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _post.intents
                    .map((i) => GestureDetector(
                          onTap: () => _navigateToUser(i.nick, i.uid),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: kBorder),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(i.nick, style: const TextStyle(fontSize: 12, color: kMuted)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── 評価 ─────────────────────────────────────────
            if (_post.ratings.isNotEmpty) ...[
              SectionLabel('評価 — ${_post.ratings.length}件'),
              ..._post.ratings.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => _navigateToUser(r.fromNick, r.fromUid),
                          child: Text(r.fromNick,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: kGold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0x66c9a84c))),
                        ),
                        const Text(' → ', style: TextStyle(fontSize: 10, color: kDim)),
                        Text(r.toNick, style: const TextStyle(fontSize: 10, color: kDim)),
                        const SizedBox(width: 8),
                        CategoryTag(r.role == 'host' ? '開催者' : '参加者', color: r.role == 'host' ? kGold : kGreen),
                        const SizedBox(width: 8),
                        Text('★' * r.stars + '☆' * (5 - r.stars), style: const TextStyle(fontSize: 11, color: kGold)),
                      ]),
                      const SizedBox(height: 4),
                      Text(r.comment, style: const TextStyle(fontSize: 12, color: kMuted)),
                      const Divider(color: Color(0xFF1a1816)),
                    ]),
                  )),
              const SizedBox(height: 4),
            ],

            // ── コメント ──────────────────────────────────────
            SectionLabel('コメント — ${_comments.length}件'),
            if (_err.isNotEmpty) ErrorBanner(message: _err, onDismiss: () => setState(() => _err = '')),

            // 投稿フォーム
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: kCard,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: kText, fontSize: 13, height: 1.8),
                  decoration: const InputDecoration(hintText: 'コメントを書く...'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'コメントを投稿 →',
                  loading: _submitting,
                  onPressed: _commentCtrl.text.trim().isNotEmpty ? _submitComment : null,
                ),
              ]),
            ),

            // コメント一覧
            if (_loadingComments)
              const Center(child: CircularProgressIndicator(color: kGold))
            else if (_comments.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('まだコメントがありません', style: TextStyle(fontSize: 13, color: kDim)),
              ))
            else
              ..._comments.map((c) => _CommentTile(
                    comment: c,
                    onTapName: () => _navigateToUser(c.nick, c.uid),
                  )),
          ],
        ),
      );

  void _showRatingSheet() {
    int stars = 0;
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('評価を送る', style: TextStyle(fontSize: 15, color: kText, letterSpacing: 1)),
            const SizedBox(height: 16),
            StarInput(value: stars, onChanged: (v) => setS(() => stars = v)),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              style: const TextStyle(color: kText, fontSize: 13),
              decoration: const InputDecoration(hintText: '楽しかった点など…'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: GoldButton(
                label: '評価を送る →',
                onPressed: stars > 0 && commentCtrl.text.isNotEmpty
                    ? () async {
                        final rating = NomikaiRating(
                          postId: '',
                          fromNick: widget.myNick,
                          fromUid: widget.myUid,
                          toUid: _isAuthor ? '参加者' : _post.authorUid,
                          toNick: _isAuthor ? '参加者' : _post.authorNick,
                          role: _isAuthor ? 'host' : 'guest',
                          stars: stars,
                          comment: commentCtrl.text.trim(),
                          createdAt: Timestamp.now(),
                        );
                        final updated = _post.copyWith(ratings: [..._post.ratings, rating]);
                        await _postRepository.updatePost(updated);
                        ref.read(postsProvider.notifier).updatePost(updated);
                        setState(() => _post = updated);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      }
                    : null,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: GoldButton(
                label: 'キャンセル',
                outline: true,
                onPressed: () => Navigator.of(ctx).pop(),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showReportSheet() {
    String? reason;
    final detailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('投稿を通報する', style: TextStyle(fontSize: 15, color: kText)),
            const SizedBox(height: 16),
            ...kReportReasons.map((r) => GestureDetector(
                  onTap: () => setS(() => reason = r),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: reason == r ? kGold : kBorder),
                      color: reason == r ? kGold.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                    child: Text(reason == r ? '✓ $r' : r,
                        style: TextStyle(fontSize: 12, color: reason == r ? kGold : kMuted)),
                  ),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: detailCtrl,
              maxLines: 2,
              style: const TextStyle(color: kText, fontSize: 13),
              decoration: const InputDecoration(hintText: '詳細（任意）'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: GoldButton(
                label: '通報する',
                danger: true,
                onPressed: reason != null
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);

                        await _reportRepository.addReport(Report(
                          postId: _post.id,
                          authorNick: _post.authorNick,
                          reporterUid: widget.myUid,
                          reporterNick: widget.myNick,
                          reason: reason!,
                          detail: detailCtrl.text,
                          createdAt: Timestamp.now(),
                        ));
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        messenger.showSnackBar(const SnackBar(content: Text('通報を受け付けました')));
                      }
                    : null,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: GoldButton(
                label: 'キャンセル',
                outline: true,
                onPressed: () => Navigator.of(ctx).pop(),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _IC extends StatelessWidget {
  final String icon, label;
  const _IC(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Text('$icon $label', style: const TextStyle(fontSize: 12, color: kMuted));
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final VoidCallback onTapName;
  const _CommentTile({required this.comment, required this.onTapName});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: onTapName,
            child: Text(comment.nick,
                style: const TextStyle(
                  fontSize: 13,
                  color: kGold,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0x66c9a84c),
                )),
          ),
          Text(
            DateFormat('yyyy年M月d日').format(comment.createdAt.toDate()),
            style: const TextStyle(fontSize: 10, color: kDim),
          ),
        ]),
        const SizedBox(height: 6),
        Text(comment.text, style: const TextStyle(fontSize: 13, color: kMuted, height: 1.8)),
        const Divider(color: Color(0xFF1a1816)),
      ]);
}
