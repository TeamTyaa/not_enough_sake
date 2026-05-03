// ══════════════════════════════════════════════════════════
// お知らせプロバイダ
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notice.dart';
import '../repositories/notice_repository.dart';

class NoticesState {
  final List<AppNotice> all;
  final List<String> readIds;

  const NoticesState({this.all = const [], this.readIds = const []});

  List<AppNotice> get active {
    return all.where((n) => n.isActive).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  final _noticeRepository = NoticeRepository();

  Future<void> _load() async {
    try {
      final notices = await _noticeRepository.getNotices();
      final readIds = await _noticeRepository.getReadIds();
      state = NoticesState(all: notices, readIds: readIds);
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    if (state.readIds.contains(id)) return;
    final next = [...state.readIds, id];
    await _noticeRepository.setReadIds(next);
    state = state.copyWith(readIds: next);
  }
}

final noticesProvider = StateNotifierProvider<NoticesNotifier, NoticesState>(
  (_) => NoticesNotifier(),
);
