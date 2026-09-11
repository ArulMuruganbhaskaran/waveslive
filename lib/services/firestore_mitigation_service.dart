import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/hazard_model.dart';
import '../core/constants/app_constants.dart';

const _uuid = Uuid();

/// Firestore mitigation service.
/// Drop-in replacement for MockMitigationService.
class FirestoreMitigationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _actions =>
      _db.collection('mitigation_actions');

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<MitigationActionModel>> getAllActions() async {
    final snap =
        await _actions.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => MitigationActionModel.fromFirestore(d))
        .toList();
  }

  Future<MitigationActionModel?> getActionByHazardId(
      String hazardId) async {
    final snap = await _actions
        .where('hazardId', isEqualTo: hazardId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MitigationActionModel.fromFirestore(snap.docs.first);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<MitigationActionModel> createAction({
    required String hazardId,
    required String reportId,
    required String hazardType,
    required String severity,
    required String actionTaken,
    required String assignedTeam,
    required String safetyInstructions,
    required String officerId,
    required String officerName,
  }) async {
    final actionId = _uuid.v4();
    final now = DateTime.now();
    final initialEntry = MitigationStatusUpdateModel(
      status: IncidentStatus.inProgress,
      note: 'Mitigation action created and initiated.',
      updatedById: officerId,
      updatedAt: now,
    );

    final action = MitigationActionModel(
      id: actionId,
      hazardId: hazardId,
      reportId: reportId,
      hazardType: hazardType,
      severity: severity,
      actionTaken: actionTaken,
      assignedTeam: assignedTeam,
      safetyInstructions: safetyInstructions,
      status: IncidentStatus.inProgress,
      officerId: officerId,
      officerName: officerName,
      createdAt: now,
      statusHistory: [initialEntry],
    );

    // Batch write: create action + update hazard status
    final batch = _db.batch();
    batch.set(_actions.doc(actionId), action.toFirestore());
    batch.update(_db.collection('hazards').doc(hazardId), {
      'incidentStatus': IncidentStatus.inProgress,
    });
    batch.update(_db.collection('reports').doc(reportId), {
      'incidentStatus': IncidentStatus.inProgress,
      'lastUpdatedAt': now.toIso8601String(),
    });
    await batch.commit();

    return action;
  }

  Future<MitigationActionModel> updateStatus({
    required String actionId,
    required String newStatus,
    required String note,
    required String officerId,
  }) async {
    final doc = await _actions.doc(actionId).get();
    if (!doc.exists) throw Exception('Mitigation action not found');
    final action = MitigationActionModel.fromFirestore(doc);

    final updateEntry = MitigationStatusUpdateModel(
      status: newStatus,
      note: note,
      updatedById: officerId,
      updatedAt: DateTime.now(),
    );

    final updatedHistory = [...action.statusHistory, updateEntry];
    final isComplete = newStatus == IncidentStatus.resolved ||
        newStatus == IncidentStatus.mitigated;

    // Batch update: action + hazard + report
    final batch = _db.batch();
    batch.update(_actions.doc(actionId), {
      'status': newStatus,
      'statusHistory': updatedHistory.map((e) => e.toMap()).toList(),
      'lastUpdatedAt': DateTime.now().toIso8601String(),
      if (isComplete) 'completedAt': DateTime.now().toIso8601String(),
    });
    batch.update(_db.collection('hazards').doc(action.hazardId), {
      'incidentStatus': newStatus,
      if (newStatus == IncidentStatus.resolved)
        'resolvedAt': DateTime.now().toIso8601String(),
    });
    batch.update(_db.collection('reports').doc(action.reportId), {
      'incidentStatus': newStatus,
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });
    await batch.commit();

    final updated = await _actions.doc(actionId).get();
    return MitigationActionModel.fromFirestore(updated);
  }
}
