import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/cycle_report.dart';

class CycleReportRepository {
  final FirebaseFirestore _firestore;

  CycleReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Reports will be stored under /groups/{groupId}/cycle_reports/{cycleId}
  CollectionReference<Map<String, dynamic>> _reportsRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('cycle_reports');

  Future<CycleReport?> getReport(String groupId, String cycleId) async {
    final docSnap = await _reportsRef(groupId).doc(cycleId).get();
    if (!docSnap.exists) {
      return null;
    }
    final data = docSnap.data()!;
    // Optional: Handle date conversions if needed, but freezed + json_serializable should handle DateTime assuming correct JSON format.

    // json_serializable espera ISO-8601; Firestore retorna Timestamp.
    for (final key in [
      'generatedAt',
      'generatedForStartDate',
      'generatedForEndDate',
    ]) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }

    return CycleReport.fromJson(data);
  }

  Future<void> saveReport(CycleReport report) async {
    final json = report.toJson();
    for (final key in [
      'generatedAt',
      'generatedForStartDate',
      'generatedForEndDate',
    ]) {
      if (json[key] is String) {
        json[key] = Timestamp.fromDate(DateTime.parse(json[key] as String));
      }
    }

    await _reportsRef(report.groupId).doc(report.cycleId).set(json);
  }
}
