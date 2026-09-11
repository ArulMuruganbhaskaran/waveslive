import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/hazard_model.dart';
import '../core/constants/app_constants.dart';

const _uuid = Uuid();

/// Firestore alert service.
/// Drop-in replacement for MockAlertService.
class FirestoreAlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection('alerts');

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<AlertModel>> getAlertsForOfficer(String officerId) async {
    final snap = await _alerts
        .where('targetOfficerId', isEqualTo: officerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => AlertModel.fromFirestore(d)).toList();
  }

  Future<int> getUnreadCount(String officerId) async {
    final snap = await _alerts
        .where('targetOfficerId', isEqualTo: officerId)
        .where('isRead', isEqualTo: false)
        .get();
    return snap.size;
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  Stream<List<AlertModel>> watchAlertsForOfficer(String officerId) {
    return _alerts
        .where('targetOfficerId', isEqualTo: officerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AlertModel.fromFirestore(d)).toList());
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> markAlertRead(String alertId) async {
    await _alerts.doc(alertId).update({'isRead': true});
  }

  Future<void> createAlertFromHazard({
    required HazardModel hazard,
    required String reportId,
    required String officerId,
    required String recommendation,
  }) async {
    final alertId = _uuid.v4();
    final alert = AlertModel(
      id: alertId,
      hazardId: hazard.id,
      reportId: reportId,
      hazardType: hazard.hazardType,
      level: hazard.severity == HazardSeverity.critical
          ? AlertLevel.critical
          : AlertLevel.high,
      severity: hazard.severity,
      locationName: hazard.locationName,
      latitude: hazard.latitude,
      longitude: hazard.longitude,
      confidenceScore: hazard.confidenceScore,
      verificationStatus: hazard.verificationStatus,
      recommendedAction: recommendation,
      createdAt: DateTime.now(),
      targetOfficerId: officerId,
    );
    await _alerts.doc(alertId).set(alert.toFirestore());
  }
}
