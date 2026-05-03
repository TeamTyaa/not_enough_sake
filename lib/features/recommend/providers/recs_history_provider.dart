// ══════════════════════════════════════════════════════════
// おすすめ履歴プロバイダー
// ══════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recs_history_item.dart';
import '../repositories/recommend_repository.dart';

final recsHistoryProvider = FutureProvider.autoDispose.family<List<RecsHistoryItem>, String>(
  (_, uid) => RecommendRepository().getHistory(uid),
);
