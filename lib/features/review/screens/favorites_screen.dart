// ══════════════════════════════════════════════════════════
// お気に入り画面
// ══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/constants.dart';
import '../../../widgets/actions/purchase_links.dart';
import '../../../widgets/layout/nomigatari_app_bar.dart';
import '../../../widgets/media/drink_image.dart';
import '../providers/favorite_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  final String uid;
  const FavoritesScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider(uid));
    return Scaffold(
      appBar: nomigatariAppBar(title: 'お気に入りランキング', onBack: () => Navigator.of(context).pop()),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '全スライダー「ちょうどいい」のお酒が自動登録。長押し→ドラッグで並び替え。',
            style: const TextStyle(fontSize: 11, color: kDim, height: 1.7),
          ),
        ),
        Expanded(
          child: favs.isEmpty
              ? const Center(child: Text('まだお気に入りがありません', style: TextStyle(fontSize: 13, color: kDim)))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  itemCount: favs.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    ref.read(favoritesProvider(uid).notifier).reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (ctx, i) {
                    final fav = favs[i];
                    return Container(
                      key: ValueKey(fav.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a0806),
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Row(children: [
                        SizedBox(
                          width: 60,
                          child: Stack(children: [
                            DrinkImage(name: fav.name, category: fav.category, height: 60, width: 60),
                            Positioned(
                                top: 3,
                                left: 5,
                                child: Text('${i + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: i == 0
                                          ? kGold
                                          : i == 1
                                              ? const Color(0xFF9a9a9a)
                                              : i == 2
                                                  ? const Color(0xFFc07a5a)
                                                  : kDim,
                                      shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                                    ))),
                          ]),
                        ),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fav.name, style: const TextStyle(fontSize: 13, color: kText)),
                            Text(fav.category, style: const TextStyle(fontSize: 10, color: kDim)),
                            const SizedBox(height: 4),
                            PurchaseLinks(name: fav.name),
                          ]),
                        )),
                        const Icon(Icons.drag_handle, color: Color(0xFF2e2820), size: 20),
                        const SizedBox(width: 8),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
