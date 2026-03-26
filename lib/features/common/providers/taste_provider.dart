// ══════════════════════════════════════════════════════════
// 好みタステプロバイダー（合成）
// ══════════════════════════════════════════════════════════
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../../review/models/drink_review.dart';
import '../models/taste_profile.dart';

final myTasteProvider = Provider.family<TasteProfile, (TasteProfile, List<DrinkReview>)>(
  (_, args) {
    final base = args.$1;
    final reviews = args.$2;
    if (reviews.length < kReviewThreshold) return base;
    final avg = TasteProfile.average(reviews.map((r) => r.sliders).toList());
    return TasteProfile(
      sweet: ((base.sweet + avg.sweet) / 2).round(),
      body: ((base.body + avg.body) / 2).round(),
      aroma: ((base.aroma + avg.aroma) / 2).round(),
      finish: ((base.finish + avg.finish) / 2).round(),
      kick: ((base.kick + avg.kick) / 2).round(),
    );
  },
);
