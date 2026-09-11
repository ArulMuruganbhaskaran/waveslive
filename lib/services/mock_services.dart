import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/hazard_model.dart';
import '../core/constants/app_constants.dart';
import 'mock_data_store.dart';

const _uuid = Uuid();

/// Mock service for data acquisition (report submission)
class MockDataAcquisitionService {
  final _store = MockDataStore.instance;

  Future<List<ReportModel>> getReportsForAgent(String agentId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _store.reports
        .where((r) => r.agentId == agentId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<ReportModel> submitReport({
    required String agentId,
    required String agentName,
    required String imagePath,
    required double latitude,
    required double longitude,
    String? locationName,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final report = ReportModel(
      id: _uuid.v4(),
      agentId: agentId,
      agentName: agentName,
      imagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      capturedAt: DateTime.now(),
      description: description,
      processingStatus: ProcessingStatus.processing,
      verificationStatus: VerificationStatus.pending,
      incidentStatus: IncidentStatus.pending,
      submittedAt: DateTime.now(),
    );

    _store.reports.insert(0, report);
    return report;
  }

  Future<ReportModel?> getReportById(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _store.reports.firstWhere((r) => r.id == reportId);
    } catch (_) {
      return null;
    }
  }

  Future<ReportModel> updateReportWithProcessingResult({
    required String reportId,
    required ProcessingResultModel result,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _store.reports.indexWhere((r) => r.id == reportId);
    if (idx < 0) throw Exception('Report not found');

    final updated = _store.reports[idx].copyWith(
      processingStatus: ProcessingStatus.completed,
      processingResult: result,
      lastUpdatedAt: DateTime.now(),
    );
    _store.reports[idx] = updated;
    return updated;
  }
}

/// Mock service for verification
class MockVerificationService {
  final _store = MockDataStore.instance;

  Future<List<ReportModel>> getPendingVerifications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _store.reports
        .where((r) =>
            r.processingStatus == ProcessingStatus.completed &&
            r.processingResult?.hazardDetected == true &&
            r.verificationStatus == VerificationStatus.pending)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<List<ReportModel>> getVerifiedReports(String verifierId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _store.reports
        .where((r) => r.verifications.any((v) => v.verifierId == verifierId))
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<ReportModel> submitVerification({
    required String reportId,
    required VerificationEntryModel entry,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final idx = _store.reports.indexWhere((r) => r.id == reportId);
    if (idx < 0) throw Exception('Report not found');

    final existing = _store.reports[idx];
    final updatedVerifications = [...existing.verifications, entry];

    // Calculate overall verification status
    final genuineCount = updatedVerifications
        .where((v) => v.result == VerificationResult.genuine)
        .length;
    final falseCount = updatedVerifications
        .where((v) => v.result == VerificationResult.falsified)
        .length;
    final suspiciousCount = updatedVerifications
        .where((v) => v.result == VerificationResult.suspicious)
        .length;

    String overallStatus;
    if (updatedVerifications.isEmpty) {
      overallStatus = VerificationStatus.pending;
    } else if (genuineCount > falseCount && genuineCount > suspiciousCount) {
      overallStatus = VerificationStatus.verified;
    } else if (falseCount >= genuineCount) {
      overallStatus = VerificationStatus.rejected;
    } else {
      overallStatus = VerificationStatus.suspicious;
    }

    final updated = existing.copyWith(
      verifications: updatedVerifications,
      verificationStatus: overallStatus,
      lastUpdatedAt: DateTime.now(),
    );
    _store.reports[idx] = updated;
    return updated;
  }

  VerificationSummaryModel getSummary(List<VerificationEntryModel> verifications) {
    final genuineCount =
        verifications.where((v) => v.result == VerificationResult.genuine).length;
    final suspiciousCount =
        verifications.where((v) => v.result == VerificationResult.suspicious).length;
    final falseCount =
        verifications.where((v) => v.result == VerificationResult.falsified).length;

    String overallStatus;
    if (verifications.isEmpty) {
      overallStatus = VerificationStatus.pending;
    } else if (genuineCount > falseCount && genuineCount > suspiciousCount) {
      overallStatus = VerificationStatus.verified;
    } else if (falseCount >= genuineCount) {
      overallStatus = VerificationStatus.rejected;
    } else {
      overallStatus = VerificationStatus.suspicious;
    }

    return VerificationSummaryModel(
      genuineCount: genuineCount,
      suspiciousCount: suspiciousCount,
      falseCount: falseCount,
      overallStatus: overallStatus,
    );
  }
}

/// Mock service for hazard monitoring
class MockHazardMonitoringService {
  final _store = MockDataStore.instance;

  Future<List<HazardModel>> getAllHazards() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_store.hazards)
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  Future<List<HazardModel>> getActiveHazards() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _store.hazards
        .where((h) =>
            h.incidentStatus != IncidentStatus.resolved)
        .toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  Future<List<HazardModel>> getHazardsByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _store.hazards
        .where((h) => h.incidentStatus == status)
        .toList();
  }

  Future<HazardModel?> getHazardByReportId(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _store.hazards.firstWhere((h) => h.reportId == reportId);
    } catch (_) {
      return null;
    }
  }

  Future<void> createHazardFromReport(ReportModel report) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (report.processingResult == null) return;

    // Don't create duplicate
    final exists = _store.hazards.any((h) => h.reportId == report.id);
    if (exists) return;

    final hazard = HazardModel(
      id: const Uuid().v4(),
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

    _store.hazards.add(hazard);
  }

  Future<HazardModel> updateHazardStatus(String hazardId, String status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _store.hazards.indexWhere((h) => h.id == hazardId);
    if (idx < 0) throw Exception('Hazard not found');

    final updated = _store.hazards[idx].copyWith(
      incidentStatus: status,
      resolvedAt: status == IncidentStatus.resolved ? DateTime.now() : null,
    );
    _store.hazards[idx] = updated;
    return updated;
  }

  Map<String, int> getDashboardStats() {
    final active = _store.hazards
        .where((h) =>
            h.incidentStatus != IncidentStatus.resolved)
        .length;
    final pending = _store.hazards
        .where((h) => h.incidentStatus == IncidentStatus.pending)
        .length;
    final highRisk = _store.hazards
        .where((h) =>
            (h.severity == HazardSeverity.high ||
                h.severity == HazardSeverity.critical) &&
            h.incidentStatus != IncidentStatus.resolved)
        .length;
    final resolved = _store.hazards
        .where((h) => h.incidentStatus == IncidentStatus.resolved)
        .length;

    // Pending verifications
    final pendingVerif = _store.reports
        .where((r) =>
            r.processingStatus == ProcessingStatus.completed &&
            r.verificationStatus == VerificationStatus.pending)
        .length;

    return {
      'active': active,
      'pending': pending,
      'highRisk': highRisk,
      'resolved': resolved,
      'pendingVerification': pendingVerif,
    };
  }
}

/// Mock alert service
class MockAlertService {
  final _store = MockDataStore.instance;

  Future<List<AlertModel>> getAlertsForOfficer(String officerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _store.alerts
        .where((a) =>
            a.targetOfficerId == officerId || a.targetOfficerId == null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markAlertRead(String alertId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _store.alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _store.alerts[idx] = _store.alerts[idx].copyWith(isRead: true);
    }
  }

  int getUnreadCount(String officerId) {
    return _store.alerts
        .where((a) =>
            !a.isRead &&
            (a.targetOfficerId == officerId || a.targetOfficerId == null))
        .length;
  }

  Future<void> createAlertFromHazard({
    required HazardModel hazard,
    required String reportId,
    required String officerId,
    required String recommendation,
  }) async {
    final alert = AlertModel(
      id: const Uuid().v4(),
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
    _store.alerts.insert(0, alert);
  }
}

/// Mock mitigation service
class MockMitigationService {
  final _store = MockDataStore.instance;

  Future<List<MitigationActionModel>> getAllActions() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_store.mitigationActions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<MitigationActionModel?> getActionByHazardId(String hazardId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _store.mitigationActions.firstWhere((m) => m.hazardId == hazardId);
    } catch (_) {
      return null;
    }
  }

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
    await Future.delayed(const Duration(milliseconds: 700));

    final now = DateTime.now();
    final action = MitigationActionModel(
      id: const Uuid().v4(),
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
      statusHistory: [
        MitigationStatusUpdateModel(
          status: IncidentStatus.inProgress,
          note: 'Mitigation action created and initiated.',
          updatedById: officerId,
          updatedAt: now,
        ),
      ],
    );

    _store.mitigationActions.add(action);

    // Update hazard status
    final hazardIdx = _store.hazards.indexWhere((h) => h.id == hazardId);
    if (hazardIdx >= 0) {
      _store.hazards[hazardIdx] = _store.hazards[hazardIdx].copyWith(
        incidentStatus: IncidentStatus.inProgress,
      );
    }

    return action;
  }

  Future<MitigationActionModel> updateStatus({
    required String actionId,
    required String newStatus,
    required String note,
    required String officerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final idx = _store.mitigationActions.indexWhere((m) => m.id == actionId);
    if (idx < 0) throw Exception('Mitigation action not found');

    final action = _store.mitigationActions[idx];
    final updateEntry = MitigationStatusUpdateModel(
      status: newStatus,
      note: note,
      updatedById: officerId,
      updatedAt: DateTime.now(),
    );

    final updated = action.copyWith(
      status: newStatus,
      statusHistory: [...action.statusHistory, updateEntry],
      lastUpdatedAt: DateTime.now(),
      completedAt: (newStatus == IncidentStatus.resolved ||
              newStatus == IncidentStatus.mitigated)
          ? DateTime.now()
          : null,
    );

    _store.mitigationActions[idx] = updated;

    // Update hazard status too
    final hazardIdx = _store.hazards.indexWhere((h) => h.id == action.hazardId);
    if (hazardIdx >= 0) {
      _store.hazards[hazardIdx] = _store.hazards[hazardIdx].copyWith(
        incidentStatus: newStatus,
        resolvedAt: newStatus == IncidentStatus.resolved ? DateTime.now() : null,
      );
    }

    // Update report status too
    final reportIdx = _store.reports.indexWhere((r) => r.id == action.reportId);
    if (reportIdx >= 0) {
      _store.reports[reportIdx] = _store.reports[reportIdx].copyWith(
        incidentStatus: newStatus,
        lastUpdatedAt: DateTime.now(),
      );
    }

    return updated;
  }
}

/// Mock report management service
class MockReportManagementService {
  final _store = MockDataStore.instance;

  Future<List<ReportModel>> getAllReports({
    String? dateFilter,
    String? hazardTypeFilter,
    String? severityFilter,
    String? verificationStatusFilter,
    String? incidentStatusFilter,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    var filtered = List<ReportModel>.from(_store.reports);

    if (hazardTypeFilter != null && hazardTypeFilter.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.processingResult?.hazardType == hazardTypeFilter)
          .toList();
    }

    if (severityFilter != null && severityFilter.isNotEmpty) {
      filtered = filtered
          .where((r) => r.processingResult?.severity == severityFilter)
          .toList();
    }

    if (verificationStatusFilter != null &&
        verificationStatusFilter.isNotEmpty) {
      filtered = filtered
          .where((r) => r.verificationStatus == verificationStatusFilter)
          .toList();
    }

    if (incidentStatusFilter != null && incidentStatusFilter.isNotEmpty) {
      filtered = filtered
          .where((r) => r.incidentStatus == incidentStatusFilter)
          .toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where((r) =>
              r.locationName?.toLowerCase().contains(q) == true ||
              r.agentName.toLowerCase().contains(q) ||
              r.processingResult?.hazardType.toLowerCase().contains(q) == true ||
              r.displayId.toLowerCase().contains(q))
          .toList();
    }

    filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return filtered;
  }

  Future<ReportModel?> getReportById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _store.reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
