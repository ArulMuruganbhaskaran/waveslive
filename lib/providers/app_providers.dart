import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../models/hazard_model.dart';
import '../core/constants/app_constants.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_report_service.dart';
import '../services/firestore_hazard_service.dart';
import '../services/firestore_alert_service.dart';
import '../services/firestore_mitigation_service.dart';
import '../services/mock_model_processing_service.dart';
import '../services/image_validation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service Providers (singletons)
// ─────────────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final modelProcessingServiceProvider =
    Provider<MockModelProcessingService>((ref) {
  return MockModelProcessingService();
});

final imageValidationServiceProvider =
    Provider<ImageValidationService>((ref) {
  return ImageValidationService();
});

final dataAcquisitionServiceProvider =
    Provider<FirestoreReportService>((ref) {
  return FirestoreReportService();
});

final verificationServiceProvider =
    Provider<FirestoreReportService>((ref) {
  return FirestoreReportService();
});

final hazardMonitoringServiceProvider =
    Provider<FirestoreHazardService>((ref) {
  return FirestoreHazardService();
});

final alertServiceProvider = Provider<FirestoreAlertService>((ref) {
  return FirestoreAlertService();
});

final mitigationServiceProvider = Provider<FirestoreMitigationService>((ref) {
  return FirestoreMitigationService();
});

final reportManagementServiceProvider =
    Provider<FirestoreReportService>((ref) {
  return FirestoreReportService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth State  (now backed by Firebase Auth stream)
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FirebaseAuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      final user = await _authService.updateProfile(updatedUser);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});

// ─────────────────────────────────────────────────────────────────────────────
// Report Providers
// ─────────────────────────────────────────────────────────────────────────────

class ReportsNotifier
    extends StateNotifier<AsyncValue<List<ReportModel>>> {
  final FirestoreReportService _service;
  final String? _agentId;

  ReportsNotifier(this._service, this._agentId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      if (_agentId != null) {
        final reports = await _service.getReportsForAgent(_agentId);
        state = AsyncValue.data(reports);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ReportModel?> submitReport({
    required String agentId,
    required String agentName,
    required String imagePath,
    required double latitude,
    required double longitude,
    String? locationName,
    String? description,
  }) async {
    try {
      // imagePath is a local path here — the service will upload it.
      // We pass a dummy XFile-like wrapper; the actual upload logic in
      // FirestoreReportService.submitReport accepts XFile directly.
      // For now delegate to the mock path for compatibility.
      final report = await _service.submitReportFromPath(
        agentId: agentId,
        agentName: agentName,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        description: description,
      );
      await load();
      return report;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateWithProcessingResult({
    required String reportId,
    required ProcessingResultModel result,
  }) async {
    await _service.updateReportWithProcessingResult(
      reportId: reportId,
      result: result,
    );
    await load();
  }
}

final agentReportsProvider = StateNotifierProvider.family<ReportsNotifier,
    AsyncValue<List<ReportModel>>, String?>(
  (ref, agentId) => ReportsNotifier(
    ref.watch(dataAcquisitionServiceProvider),
    agentId,
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Verification Providers
// ─────────────────────────────────────────────────────────────────────────────

final pendingVerificationsProvider =
    FutureProvider<List<ReportModel>>((ref) async {
  final service = ref.watch(verificationServiceProvider);
  return service.getPendingVerifications();
});

final verificationHistoryProvider =
    FutureProvider.family<List<ReportModel>, String>(
        (ref, verifierId) async {
  final service = ref.watch(verificationServiceProvider);
  return service.getVerifiedReports(verifierId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Hazard Monitoring Providers
// ─────────────────────────────────────────────────────────────────────────────

final allHazardsProvider = FutureProvider<List<HazardModel>>((ref) async {
  final service = ref.watch(hazardMonitoringServiceProvider);
  return service.getAllHazards();
});

final activeHazardsProvider =
    FutureProvider<List<HazardModel>>((ref) async {
  final service = ref.watch(hazardMonitoringServiceProvider);
  return service.getActiveHazards();
});

final dashboardStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(hazardMonitoringServiceProvider);
  return service.getDashboardStats();
});

// ─────────────────────────────────────────────────────────────────────────────
// Alert Providers
// ─────────────────────────────────────────────────────────────────────────────

final alertsProvider =
    FutureProvider.family<List<AlertModel>, String>((ref, officerId) async {
  final service = ref.watch(alertServiceProvider);
  return service.getAlertsForOfficer(officerId);
});

final unreadAlertCountProvider =
    FutureProvider.family<int, String>((ref, officerId) async {
  final service = ref.watch(alertServiceProvider);
  return service.getUnreadCount(officerId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Mitigation Providers
// ─────────────────────────────────────────────────────────────────────────────

final mitigationActionsProvider =
    FutureProvider<List<MitigationActionModel>>((ref) async {
  final service = ref.watch(mitigationServiceProvider);
  return service.getAllActions();
});

// ─────────────────────────────────────────────────────────────────────────────
// Report Management Providers
// ─────────────────────────────────────────────────────────────────────────────

class ReportFilterNotifier extends StateNotifier<Map<String, String>> {
  ReportFilterNotifier() : super({});

  void setFilter(String key, String value) {
    state = {...state, key: value};
  }

  void clearFilter(String key) {
    final newState = {...state};
    newState.remove(key);
    state = newState;
  }

  void clearAll() {
    state = {};
  }
}

final reportFilterProvider =
    StateNotifierProvider<ReportFilterNotifier, Map<String, String>>(
  (ref) => ReportFilterNotifier(),
);

final filteredReportsProvider =
    FutureProvider<List<ReportModel>>((ref) async {
  final service = ref.watch(reportManagementServiceProvider);
  final filters = ref.watch(reportFilterProvider);

  return service.getAllReports(
    hazardTypeFilter: filters['hazardType'],
    severityFilter: filters['severity'],
    verificationStatusFilter: filters['verificationStatus'],
    incidentStatusFilter: filters['incidentStatus'],
    searchQuery: filters['search'],
  );
});

/// All reports that have completed AI processing results — shown on officer dashboard.
final aiProcessedReportsProvider =
    FutureProvider<List<ReportModel>>((ref) async {
  final service = ref.watch(reportManagementServiceProvider);
  final all = await service.getAllReports();
  return all
      .where((r) =>
          r.processingStatus == ProcessingStatus.completed &&
          r.processingResult != null)
      .toList()
    ..sort((a, b) => (b.lastUpdatedAt ?? b.submittedAt)
        .compareTo(a.lastUpdatedAt ?? a.submittedAt));
});
