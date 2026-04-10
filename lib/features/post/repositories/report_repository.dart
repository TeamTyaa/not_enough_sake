// ============================================================
// 通報データリポジトリ
// ============================================================

import '../../../services/db_service.dart';
import '../models/report.dart';

class ReportRepository {
  Future<void> addReport(Report r) async {
    await DbService.collection('reports').add(r.toMap());
  }
}
