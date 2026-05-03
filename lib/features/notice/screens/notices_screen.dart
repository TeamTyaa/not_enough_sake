// ══════════════════════════════════════════════════════════
// お知らせ画面
// ══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../providers/notice_provider.dart';

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesState = ref.watch(noticesProvider);
    final active = noticesState.active;

    return Scaffold(
      appBar: nomigatariAppBar(title: 'お知らせ', onBack: () => Navigator.of(context).pop()),
      body: active.isEmpty
          ? const Center(child: Text('現在お知らせはありません', style: TextStyle(fontSize: 13, color: kDim)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: active.length,
              itemBuilder: (_, i) {
                final notice = active[i];
                final isRead = noticesState.readIds.contains(notice.id);
                return GestureDetector(
                  onTap: () => ref.read(noticesProvider.notifier).markRead(notice.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kCard,
                      border: Border.all(color: isRead ? kBorder : kGold.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        if (!isRead) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                            child: Text(notice.title, style: TextStyle(fontSize: 15, color: isRead ? kMuted : kText))),
                      ]),
                      const SizedBox(height: 8),
                      Text(notice.body, style: const TextStyle(fontSize: 12, color: kDim, height: 1.75)),
                      const SizedBox(height: 10),
                      Text(
                        '掲載期限: ${DateFormat('yyyy年M月d日').format(notice.endAt.toDate())}',
                        style: const TextStyle(fontSize: 9, color: Color(0xFF3a3028)),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
