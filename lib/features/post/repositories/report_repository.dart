import '../../../services/db_service.dart';
import '../models/report_data.dart';

class ReportRepository {
  Future<void> addReport(ReportData r) async {
    await DbService.collection('reports').add(r.toMap());
  }
}
