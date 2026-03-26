// ══════════════════════════════════════════════════════════
// お知らせプロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/mock_db.dart';
import '../models/app_notice.dart';

class NoticesState {
  final List<AppNotice> all;
  final List<String> readIds;

  const NoticesState({this.all = const [], this.readIds = const []});

  List<AppNotice> get active {
    final today = DateTime.now();
    return all.where((n) => n.isActive(today)).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AppNotice> get unread =>
      active.where((n) => !readIds.contains(n.id)).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  NoticesState copyWith({List<AppNotice>? all, List<String>? readIds}) =>
      NoticesState(all: all ?? this.all, readIds: readIds ?? this.readIds);
}

class NoticesNotifier extends StateNotifier<NoticesState> {
  NoticesNotifier() : super(const NoticesState()) {
    _load();
  }

  void _load() {
    final notices = MockDb.getNotices();
    final readIds = MockDb.getReadNoticeIds();
    state = NoticesState(all: notices, readIds: readIds);
  }

  Future<void> markRead(String id) async {
    if (state.readIds.contains(id)) return;
    final next = [...state.readIds, id];
    await MockDb.setReadNoticeIds(next);
    state = state.copyWith(readIds: next);
  }
}

final noticesProvider = StateNotifierProvider<NoticesNotifier, NoticesState>(
  (_) => NoticesNotifier(),
);
