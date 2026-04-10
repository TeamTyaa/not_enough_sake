// ============================================================
// 飲み会掲示板画面
// ============================================================

import 'dart:math' show sqrt;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants.dart';
import '../../../widgets/buttons/gold_button.dart';
import '../../../widgets/cards/category_tag.dart';
import '../../../widgets/cards/trust_badge.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/models/taste_profile.dart';
import '../../review/providers/review_provider.dart';
import '../models/nomikai_post.dart';
import '../models/post_status.dart';
import '../providers/posts_provider.dart';
import 'post_detail_screen.dart';

class NomikaiBoard extends ConsumerStatefulWidget {
  const NomikaiBoard({super.key});

  @override
  ConsumerState<NomikaiBoard> createState() => _NomikaiBoard();
}

class _NomikaiBoard extends ConsumerState<NomikaiBoard> {
  String _sort = 'recommend';
  String _filterCity = '';
  String _filterMinCap = '';
  String _filterMaxCap = '';
  int _visibleCount = kPageSize;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(postsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _dist(NomikaiPost post, TasteProfile myTaste) {
    final t = post.authorTaste;
    final ds = t.sweet - myTaste.sweet,
        db = t.body - myTaste.body,
        da = t.aroma - myTaste.aroma,
        df = t.finish - myTaste.finish,
        dk = t.kick - myTaste.kick;
    return sqrt((ds * ds + db * db + da * da + df * df + dk * dk).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final reviews = ref.watch(reviewsProvider(user.uid));
    final tasteReady = reviews.length >= kReviewThreshold;
    final posts = ref.watch(postsProvider);
    final postsState = ref.watch(postsProvider);

    if (!tasteReady) {
      return _LockedView(
        current: reviews.length,
        needed: kReviewThreshold,
      );
    }

    // ソート・フィルター
    var display = postsState.posts.where((p) => _dist(p, user.tasteProfile) <= kSimilarityThreshold).toList();

    if (_filterCity.isNotEmpty) {
      display = display.where((p) => p.place.contains(_filterCity)).toList();
    }
    if (_filterMinCap.isNotEmpty) {
      final min = int.tryParse(_filterMinCap) ?? 0;
      display = display.where((p) => p.capacity >= min).toList();
    }
    if (_filterMaxCap.isNotEmpty) {
      final max = int.tryParse(_filterMaxCap) ?? 9999;
      display = display.where((p) => p.capacity <= max).toList();
    }

    switch (_sort) {
      case 'popular':
        display.sort((a, b) => (b.intents.length).compareTo(a.intents.length));
      case 'deadline':
        display.sort((a, b) => a.date.compareTo(b.date));
      default:
        display.sort((a, b) => _dist(a, user.tasteProfile).compareTo(_dist(b, user.tasteProfile)));
    }

    final visible = display.take(_visibleCount).toList();
    final hasMore = _visibleCount < display.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kGold,
        foregroundColor: kBg,
        onPressed: () => _showNewPostSheet(context, user, user.tasteProfile, user.trustScore ?? 0),
        label: const Text('＋ 飲み会を開く', style: TextStyle(letterSpacing: 1)),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: kGold,
        backgroundColor: kCard,
        onRefresh: () => ref.read(postsProvider.notifier).loadFirst(),
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ソートボタン
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kSortOptions
                  .map((opt) => _SortChip(
                        label: opt.label,
                        selected: _sort == opt.key,
                        onTap: () => setState(() {
                          _sort = opt.key;
                          _visibleCount = kPageSize;
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // フィルター
            _FilterSection(
              city: _filterCity,
              minCap: _filterMinCap,
              maxCap: _filterMaxCap,
              onCityChanged: (v) => setState(() {
                _filterCity = v;
                _visibleCount = kPageSize;
              }),
              onMinCapChanged: (v) => setState(() {
                _filterMinCap = v;
                _visibleCount = kPageSize;
              }),
              onMaxCapChanged: (v) => setState(() {
                _filterMaxCap = v;
                _visibleCount = kPageSize;
              }),
              onClear: () => setState(() {
                _filterCity = _filterMinCap = _filterMaxCap = '';
                _visibleCount = kPageSize;
              }),
            ),
            const SizedBox(height: 8),

            Text('${display.length}件', style: const TextStyle(fontSize: 11, color: kDim)),
            const SizedBox(height: 12),

            if (visible.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Text('条件に一致する飲み会が見つかりません。', style: TextStyle(fontSize: 13, color: kDim)),
              ))
            else ...[
              ...visible.map((post) => _PostCard(
                    post: post,
                    myTaste: user.tasteProfile,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        post: post,
                        myNick: user.nickname,
                        myUid: user.uid,
                        myTaste: user.tasteProfile,
                      ),
                    )),
                  )),
              if (hasMore)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: kGold),
                )),
              if (!hasMore && display.isNotEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('すべて表示しました', style: TextStyle(fontSize: 10, color: Color(0xFF2a2018), letterSpacing: 2)),
                )),
              // ── フッター表示 ──────────────────────────────
              if (postsState.isLoadingMore)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: kGold),
                )),
              if (!postsState.hasMore && display.isNotEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('すべて表示しました', style: TextStyle(fontSize: 10, color: Color(0xFF2a2018), letterSpacing: 2)),
                )),
            ],
          ],
        ),
      ),
    );
  }

  void _showNewPostSheet(BuildContext context, AppUser user, TasteProfile myTaste, double myTrust) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => _NewPostSheet(
        authorNick: user.nickname,
        authorUid: user.uid,
        authorTaste: myTaste,
        authorTrust: myTrust,
        onSubmit: (post) async {
          await ref.read(postsProvider.notifier).addPost(post);
        },
      ),
    );
  }
}

// ── ロック画面 ────────────────────────────────────────────
class _LockedView extends StatelessWidget {
  final int current, needed;
  const _LockedView({required this.current, required this.needed});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🍶', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 14),
            const Text('好みデータを蓄積中', style: TextStyle(fontSize: 14, color: kText)),
            const SizedBox(height: 10),
            RichText(
                text: TextSpan(
              style: const TextStyle(fontSize: 12, color: kMuted, height: 1.85),
              children: [
                const TextSpan(text: '飲み会タブはレビューを '),
                TextSpan(text: '$needed本', style: const TextStyle(color: kGold)),
                const TextSpan(text: ' 以上行うと解放されます。'),
              ],
            )),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: List.generate(
                  needed,
                  (i) => Container(
                        width: 32,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < current ? kGold : const Color(0xFF2a2420),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
            ),
            const SizedBox(height: 10),
            Text('$current / $needed レビュー完了', style: const TextStyle(fontSize: 10, color: kDim)),
          ]),
        ),
      );
}

// ── ソートチップ ──────────────────────────────────────────
const kSortOptions = [
  (key: 'recommend', label: 'おすすめ順'),
  (key: 'popular', label: '参加人数が多い順'),
  (key: 'deadline', label: '締め切りが近い順'),
];

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? kGold : const Color(0xFF2a2420)),
            color: selected ? kGold.withValues(alpha: 0.12) : Colors.transparent,
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: selected ? kGold : kDim,
              )),
        ),
      );
}

// ── フィルターセクション ──────────────────────────────────
class _FilterSection extends StatelessWidget {
  final String city, minCap, maxCap;
  final ValueChanged<String> onCityChanged, onMinCapChanged, onMaxCapChanged;
  final VoidCallback onClear;
  const _FilterSection({
    required this.city,
    required this.minCap,
    required this.maxCap,
    required this.onCityChanged,
    required this.onMinCapChanged,
    required this.onMaxCapChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0a0806),
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('絞り込み', style: TextStyle(fontSize: 9, letterSpacing: 2, color: kDim)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 3,
                child: Column(children: [
                  const Align(
                      alignment: Alignment.centerLeft, child: Text('開催地', style: TextStyle(fontSize: 9, color: kDim))),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: city,
                    style: const TextStyle(color: kText, fontSize: 12),
                    decoration: const InputDecoration(hintText: '例：新宿'),
                    onChanged: onCityChanged,
                  ),
                ])),
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: Column(children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('定員 最小', style: TextStyle(fontSize: 9, color: kDim))),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: minCap,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kText, fontSize: 12),
                    decoration: const InputDecoration(hintText: '2'),
                    onChanged: onMinCapChanged,
                  ),
                ])),
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: Column(children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('定員 最大', style: TextStyle(fontSize: 9, color: kDim))),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: maxCap,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: kText, fontSize: 12),
                    decoration: const InputDecoration(hintText: '20'),
                    onChanged: onMaxCapChanged,
                  ),
                ])),
          ]),
          if (city.isNotEmpty || minCap.isNotEmpty || maxCap.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClear,
                child: const Text('✗ クリア', style: TextStyle(fontSize: 11, color: kRed)),
              ),
            ),
        ]),
      );
}

// ── 投稿カード ────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final NomikaiPost post;
  final TasteProfile myTaste;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.myTaste, required this.onTap});

  double get _dist {
    final t = post.authorTaste;
    final ds = t.sweet - myTaste.sweet,
        db = t.body - myTaste.body,
        da = t.aroma - myTaste.aroma,
        df = t.finish - myTaste.finish,
        dk = t.kick - myTaste.kick;
    return sqrt((ds * ds + db * db + da * da + df * df + dk * dk).toDouble());
  }

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

  @override
  Widget build(BuildContext context) {
    final isConfirmed = post.status == PostStatus.confirmed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: isConfirmed ? kGold.withValues(alpha: 0.35) : kBorder),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(children: [
          // ヘッダー（タップで詳細）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFF0a0806),
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Row(children: [
                  Text('● ${statusLabel[post.status] ?? post.status.name}',
                      style: TextStyle(fontSize: 10, color: statusColor[post.status] ?? kDim, letterSpacing: 1)),
                  if (post.title != null && post.title!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(post.title!,
                            style: const TextStyle(fontSize: 12, color: kText), overflow: TextOverflow.ellipsis)),
                  ],
                  if (post.genre != null) ...[
                    const SizedBox(width: 8),
                    CategoryTag(post.genre!),
                  ],
                ])),
                const Text('詳細 →', style: TextStyle(fontSize: 10, color: kGold)),
              ],
            ),
          ),

          // 本文
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(post.authorNick, style: const TextStyle(fontSize: 14, color: kGold)),
                TrustBadge(score: post.authorTrust, count: post.authorTrustCount),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 16, runSpacing: 6, children: [
                _InfoChip('📅', DateFormat('yyyy年M月d日').format(post.date.toDate())),
                _InfoChip('📍', post.place),
                _InfoChip('💴', post.budget),
                _InfoChip('👥', '${post.intents.length}/${post.capacity}人'),
              ]),
              const SizedBox(height: 8),
              Text(post.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: kMuted, height: 1.8)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon, label;
  const _InfoChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Text('$icon $label', style: const TextStyle(fontSize: 12, color: kMuted));
}

// ── 新規投稿シート ────────────────────────────────────────
class _NewPostSheet extends StatefulWidget {
  final String authorNick, authorUid;
  final TasteProfile authorTaste;
  final double authorTrust;
  final Future<void> Function(NomikaiPost) onSubmit;

  const _NewPostSheet({
    required this.authorNick,
    required this.authorUid,
    required this.authorTaste,
    required this.authorTrust,
    required this.onSubmit,
  });

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _titleCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _genreCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  String? _budget;
  DateTime? _date;
  bool _loading = false;
  String _err = '';

  @override
  void dispose() {
    for (final c in [_titleCtrl, _placeCtrl, _genreCtrl, _msgCtrl, _capCtrl, _minCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _titleCtrl.text.isNotEmpty &&
      _date != null &&
      _placeCtrl.text.isNotEmpty &&
      _budget != null &&
      _capCtrl.text.isNotEmpty &&
      _minCtrl.text.isNotEmpty &&
      _msgCtrl.text.isNotEmpty;

  DateTime get _minDate => DateTime.now().add(const Duration(days: 14));
  DateTime get _maxDate => DateTime.now().add(const Duration(days: 60));

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _err = '';
    });
    try {
      final post = NomikaiPost(
        id: '',
        title: _titleCtrl.text.trim(),
        date: Timestamp.fromDate(_date!),
        place: _placeCtrl.text.trim(),
        genre: _genreCtrl.text.isEmpty ? null : _genreCtrl.text.trim(),
        budget: _budget!,
        capacity: int.tryParse(_capCtrl.text) ?? 6,
        minAttendees: int.tryParse(_minCtrl.text) ?? 3,
        message: _msgCtrl.text.trim(),
        authorNick: widget.authorNick,
        authorUid: widget.authorUid,
        authorTaste: widget.authorTaste,
        authorTrust: widget.authorTrust,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      await widget.onSubmit(post);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _err = '投稿に失敗しました');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('NEW POST — 飲み会を開く', style: TextStyle(fontSize: 9, letterSpacing: 3, color: kDim)),
              IconButton(
                icon: const Icon(Icons.close, color: kDim),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
            _Input('タイトル', _titleCtrl, hint: '例：日本酒好き集まれ！新宿で一杯'),
            // 日時（2週間後〜2ヶ月後）
            const Text('開催日時（2週間後〜2か月後）', style: TextStyle(fontSize: 9, letterSpacing: 2, color: kDim)),
            const SizedBox(height: 7),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _minDate,
                  firstDate: _minDate,
                  lastDate: _maxDate,
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: kGold)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _date = picked);
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
                  _date == null ? '日付を選択' : _date!.toIso8601String().split('T').first,
                  style: TextStyle(fontSize: 13, color: _date == null ? kDim : kText),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Input('場所', _placeCtrl, hint: '例：新宿・居酒屋○○'),
            _Input('ジャンル（任意）', _genreCtrl, hint: '例：日本酒'),
            // 予算
            const Text('予算感', style: TextStyle(fontSize: 9, letterSpacing: 2, color: kDim)),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kBudgetOptions
                  .map((b) => GestureDetector(
                        onTap: () => setState(() => _budget = b),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: _budget == b ? kGold : const Color(0xFF2a2420)),
                            color: _budget == b ? kGold.withValues(alpha: 0.12) : Colors.transparent,
                          ),
                          child: Text(b, style: TextStyle(fontSize: 10, color: _budget == b ? kGold : kDim)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _Input('定員（人）', _capCtrl, hint: '6', keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _Input('確定必要人数', _minCtrl, hint: '3', keyboard: TextInputType.number)),
            ]),
            _Input('メッセージ', _msgCtrl, hint: 'どんな会にしたいか…', maxLines: 3),
            if (_err.isNotEmpty) ...[
              Text(_err, style: const TextStyle(fontSize: 11, color: kRed)),
              const SizedBox(height: 8),
            ],
            Row(children: [
              GoldButton(
                label: '投稿する →',
                loading: _loading,
                onPressed: _valid ? _submit : null,
              ),
              const SizedBox(width: 12),
              GoldButton(
                label: 'キャンセル',
                outline: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
            const SizedBox(height: 20),
          ]),
        ),
      );
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final int maxLines;
  final TextInputType keyboard;
  const _Input(
    this.label,
    this.ctrl, {
    this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 2, color: kDim)),
          const SizedBox(height: 7),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: const TextStyle(color: kText, fontSize: 13),
            decoration: InputDecoration(hintText: hint),
          ),
        ]),
      );
}
