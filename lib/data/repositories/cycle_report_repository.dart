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

    // We expect generatedAt to be a Timestamp in Firestore, need to convert
    if (data['generatedAt'] is Timestamp) {
      data['generatedAt'] =
          (data['generatedAt'] as Timestamp).toDate().toIso8601String();
    }

    return CycleReport.fromJson(data);
  }

  Future<void> saveReport(CycleReport report) async {
    final json = report.toJson();
    // Convert DateTime back to Timestamp for Firestore
    if (json['generatedAt'] is String) {
      json['generatedAt'] =
          Timestamp.fromDate(DateTime.parse(json['generatedAt']));
    }

    await _reportsRef(report.groupId).doc(report.cycleId).set(json);
  }
}
