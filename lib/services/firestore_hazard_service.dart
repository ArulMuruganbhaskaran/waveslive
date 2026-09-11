import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/hazard_model.dart';
import '../models/report_model.dart';
import '../core/constants/app_constants.dart';

const _uuid = Uuid();

/// Firestore hazard monitoring service.
/// Drop-in replacement for MockHazardMonitoringService.
class FirestoreHazardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _hazards =>
      _db.collection('hazards');

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<HazardModel>> getAllHazards() async {
    final snap = await _hazards
        .orderBy('detectedAt', descending: true)
        .get();
    return snap.docs.map((d) => HazardModel.fromFirestore(d)).toList();
  }

  Future<List<HazardModel>> getActiveHazards() async {
    final snap = await _hazards
        .where('incidentStatus', whereNotIn: [IncidentStatus.resolved])
        .orderBy('incidentStatus')
        .orderBy('detectedAt', descending: true)
        .get();
    return snap.docs.map((d) => HazardModel.fromFirestore(d)).toList();
  }

  Future<HazardModel?> getHazardByReportId(String reportId) async {
    final snap = await _hazards
        .where('reportId', isEqualTo: reportId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return HazardModel.fromFirestore(snap.docs.first);
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<HazardModel>> watchActiveHazards() {
    return _hazards
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HazardModel.fromFirestore(d)).toList());
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> createHazardFromReport(ReportModel report) async {
    if (report.processingResult == null) return;

    // Guard against duplicates
    final existing = await getHazardByReportId(report.id);
    if (existing != null) return;

    final hazardId = _uuid.v4();
    final hazard = HazardModel(
      id: hazardId,
      reportId: report.id,
      hazardType: report.processingResult!.hazardType,
      severity: report.processingResult!.severity,
      latitude: report.latitude,
      longitude: report.longitude,
      locationName: report.locationName,
      verificationStatus: report.verificationStatus,
      incidentStatus: IncidentStatus.pending,
      confidenceScore: report.processingResult!.confidenceScore,
      detectedAt: report.processingResult!.processedAt,
    );

    await _hazards.doc(hazardId).set(hazard.toFirestore());
  }

  Future<HazardModel> updateHazardStatus(
      String hazardId, String status) async {
    await _hazards.doc(hazardId).update({
      'incidentStatus': status,
      if (status == IncidentStatus.resolved)
        'resolvedAt': DateTime.now().toIso8601String(),
    });
    final doc = await _hazards.doc(hazardId).get();
    return HazardModel.fromFirestore(doc);
  }

  // ── Dashboard stats ───────────────────────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final all = await getAllHazards();
    final active =
        all.where((h) => h.incidentStatus != IncidentStatus.resolved).length;
    final pending =
        all.where((h) => h.incidentStatus == IncidentStatus.pending).length;
    final highRisk = all
        .where((h) =>
            (h.severity == HazardSeverity.high ||
                h.severity == HazardSeverity.critical) &&
            h.incidentStatus != IncidentStatus.resolved)
        .length;
    final resolved =
        all.where((h) => h.incidentStatus == IncidentStatus.resolved).length;

    // pending verifications count from reports collection
    final reportsSnap = await _db
        .collection('reports')
        .where('processingStatus', isEqualTo: ProcessingStatus.completed)
        .where('verificationStatus', isEqualTo: VerificationStatus.pending)
        .get();

    return {
      'active': active,
      'pending': pending,
      'highRisk': highRisk,
      'resolved': resolved,
      'pendingVerification': reportsSnap.size,
    };
  }
}
