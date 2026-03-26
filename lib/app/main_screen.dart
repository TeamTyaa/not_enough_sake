import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/models/app_user.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/mypage_screen.dart';
import '../features/notice/providers/notice_provider.dart';
import '../features/notice/screens/notices_screen.dart';
import '../features/post/screens/nomikai_board_screen.dart';
import '../features/recommend/screens/recommend_screen.dart';
import '../features/review/providers/review_provider.dart';
import '../features/review/screens/favorites_screen.dart';
import '../features/review/screens/history_screen.dart';
import '../features/token/providers/token_provider.dart';
import '../utils/constants.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _tabIndex = 0; // 0=おすすめ, 1=飲み会
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final tokens = ref.watch(tokenProvider(user.uid));
    final notices = ref.watch(noticesProvider);
    final unreadCnt = notices.unread.length;
    final reviews = ref.watch(reviewsProvider(user.uid));
    final tasteReady = reviews.length >= kReviewThreshold;

    return Scaffold(
      key: _scaffoldKey,

      // ── ハンバーガーメニュー (EndDrawer) ─────────────────
      endDrawer: _AppDrawer(
        freeTokens: tokens.free,
        paidTokens: tokens.paid,
        unreadCount: unreadCnt,
        onNavigate: (screen) {
          _scaffoldKey.currentState?.closeEndDrawer();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        user: user,
      ),

      // ── ヘッダー ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0806),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: RichText(
            text: const TextSpan(
          style: TextStyle(fontSize: 18, letterSpacing: 1, color: kText),
          children: [
            TextSpan(text: '酒語りＮ'),
          ],
        )),
        actions: [
          // ハンバーガーボタン（バッジ付き）
          Stack(alignment: Alignment.topRight, children: [
            IconButton(
              icon: const Icon(Icons.menu, color: kDim),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            if (unreadCnt > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: kGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ]),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(37),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(children: [
              _TabButton(
                label: 'おすすめ',
                selected: _tabIndex == 0,
                onTap: () => setState(() => _tabIndex = 0),
              ),
              _TabButton(
                label: '飲み会',
                selected: _tabIndex == 1,
                locked: !tasteReady,
                onTap: tasteReady ? () => setState(() => _tabIndex = 1) : null,
              ),
            ]),
          ),
        ),
      ),

      // ── ボディ ────────────────────────────────────────────
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          RecommendScreen(),
          NomikaiBoard(),
        ],
      ),
    );
  }
}

// ── タブボタン ────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? kGold : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                color: selected
                    ? kGold
                    : locked
                        ? const Color(0xFF2a2018)
                        : kDim,
              ),
            ),
            if (locked) const Text(' 🔒', style: TextStyle(fontSize: 8, color: Color(0xFF3a3028))),
          ]),
        ),
      );
}

// ── ハンバーガーDrawer ────────────────────────────────────
class _AppDrawer extends ConsumerWidget {
  final int freeTokens;
  final int paidTokens;
  final int unreadCount;
  final void Function(Widget) onNavigate;
  final AppUser user;

  const _AppDrawer({
    required this.freeTokens,
    required this.paidTokens,
    required this.unreadCount,
    required this.onNavigate,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF0d0b08),
      width: 280,
      child: Column(children: [
        // ヘッダー
        Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('MENU',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: kDim,
                )),
            IconButton(
              icon: const Icon(Icons.close, color: kDim, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),

        // トークン残高
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(children: [
            RichText(
                text: TextSpan(children: [
              TextSpan(text: '$freeTokens', style: const TextStyle(fontSize: 15, color: kGold)),
              const TextSpan(text: '  合', style: TextStyle(fontSize: 10, color: kDim)),
            ])),
            const SizedBox(width: 24),
            RichText(
                text: TextSpan(children: [
              TextSpan(text: '$paidTokens', style: const TextStyle(fontSize: 15, color: Color(0xFFc07a5a))),
              const TextSpan(text: '  升', style: TextStyle(fontSize: 10, color: kDim)),
            ])),
          ]),
        ),

        // メニュー項目
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            _DrawerItem(
              icon: '🔔',
              label: 'お知らせ',
              badge: unreadCount,
              onTap: () => onNavigate(const NoticesScreen()),
            ),
            _DrawerItem(
              icon: '📋',
              label: 'レビュー履歴',
              onTap: () => onNavigate(HistoryScreen(uid: user.uid)),
            ),
            _DrawerItem(
              icon: '⭐',
              label: 'お気に入りランキング',
              onTap: () => onNavigate(FavoritesScreen(uid: user.uid)),
            ),
            _DrawerItem(
              icon: '👤',
              label: 'マイページ',
              onTap: () => onNavigate(const MyPageScreen()),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: onTap,
        leading: Text(icon, style: const TextStyle(fontSize: 18)),
        title: Row(children: [
          Text(label, style: const TextStyle(fontSize: 13, color: kMuted)),
          if (badge > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: kGold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$badge', style: const TextStyle(fontSize: 10, color: kBg)),
            ),
          ],
        ]),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: kDim),
        tileColor: Colors.transparent,
      );
}
