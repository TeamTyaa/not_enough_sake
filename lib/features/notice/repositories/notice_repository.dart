import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/db_service.dart';
import '../models/app_notice.dart';

class NoticeRepository {
  Future<List<AppNotice>> getNotices() async {
    final now = Timestamp.fromDate(DateTime.now());

    final snap = await DbService.collection('notices')
        .where('startAt', isLessThanOrEqualTo: now)
        .where('endAt', isGreaterThanOrEqualTo: now)
        .get();

    return snap.docs.map((d) => AppNotice.fromMap(d.id, d.data())).toList();
  }

  Future<List<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('ng_read_notices') ?? [];
  }

  Future<void> setReadIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ng_read_notices', ids);
  }
}
