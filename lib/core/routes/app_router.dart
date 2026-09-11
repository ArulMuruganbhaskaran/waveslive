import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../constants/app_constants.dart';

// Screens
import '../../features/splash/splash_screen.dart';
import '../../features/user/login_screen.dart';
import '../../features/user/profile_screen.dart';
import '../../features/user/officer_dashboard.dart';
import '../../features/user/agent_dashboard.dart';
import '../../features/user/volunteer_dashboard.dart';
import '../../features/data_acquisition/data_acquisition_screen.dart';
import '../../features/data_acquisition/report_preview_screen.dart';
import '../../features/data_acquisition/my_reports_screen.dart';
import '../../features/model_processing/processing_result_screen.dart';
import '../../features/verification/verification_queue_screen.dart';
import '../../features/verification/verification_detail_screen.dart';
import '../../features/verification/verification_history_screen.dart';
import '../../features/hazard_monitoring/hazard_map_screen.dart';
import '../../features/hazard_monitoring/incident_detail_screen.dart';
import '../../features/alert/alerts_screen.dart';
import '../../features/alert/alert_detail_screen.dart';
import '../../features/mitigation/mitigation_screen.dart';
import '../../features/mitigation/create_mitigation_screen.dart';
import '../../features/report_management/report_management_screen.dart';
import '../../features/report_management/report_detail_screen.dart';
import '../../features/admin/admin_login_screen.dart';
import '../../features/admin/admin_dashboard.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const profile = '/profile';

  // Role dashboards
  static const officerDashboard = '/officer';
  static const agentDashboard = '/agent';
  static const volunteerDashboard = '/volunteer';
  static const ngoDashboard = '/ngo';

  // Data acquisition
  static const dataAcquisition = '/agent/capture';
  static const reportPreview = '/agent/preview';
  static const myReports = '/agent/reports';

  // Processing
  static const processingResult = '/processing/result';

  // Verification
  static const verificationQueue = '/verification/queue';
  static const verificationDetail = '/verification/detail';
  static const verificationHistory = '/verification/history';

  // Hazard monitoring
  static const hazardMap = '/officer/map';
  static const incidentDetail = '/officer/incident';

  // Alerts
  static const alerts = '/officer/alerts';
  static const alertDetail = '/officer/alerts/detail';

  // Mitigation
  static const mitigation = '/officer/mitigation';
  static const createMitigation = '/officer/mitigation/create';

  // Report management
  static const reportManagement = '/officer/reports';
  static const reportDetail = '/reports/detail';

  // Admin
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin/dashboard';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final user = authState.valueOrNull;
      final isLoading = authState.isLoading;

      // Allow splash through
      if (state.fullPath == AppRoutes.splash) return null;
      // Allow admin routes through without auth check
      if (state.fullPath?.startsWith('/admin') == true) return null;
      if (isLoading) return null;

      // If not logged in, redirect to login
      if (user == null && state.fullPath != AppRoutes.login) {
        return AppRoutes.login;
      }

      // If already logged in, don't show login
      if (user != null && state.fullPath == AppRoutes.login) {
        return _dashboardForRole(user.role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Officer routes
      GoRoute(
        path: AppRoutes.officerDashboard,
        builder: (context, state) => const OfficerDashboard(),
      ),
      GoRoute(
        path: AppRoutes.hazardMap,
        builder: (context, state) => const HazardMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.incidentDetail,
        builder: (context, state) {
          final hazardId = state.uri.queryParameters['id'] ?? '';
          return IncidentDetailScreen(hazardId: hazardId);
        },
      ),
      GoRoute(
        path: AppRoutes.alerts,
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alertDetail,
        builder: (context, state) {
          final alertId = state.uri.queryParameters['id'] ?? '';
          return AlertDetailScreen(alertId: alertId);
        },
      ),
      GoRoute(
        path: AppRoutes.mitigation,
        builder: (context, state) => const MitigationScreen(),
      ),
      GoRoute(
        path: AppRoutes.createMitigation,
        builder: (context, state) {
          final hazardId = state.uri.queryParameters['hazardId'] ?? '';
          return CreateMitigationScreen(hazardId: hazardId);
        },
      ),
      GoRoute(
        path: AppRoutes.reportManagement,
        builder: (context, state) => const ReportManagementScreen(),
      ),

      // Agent routes
      GoRoute(
        path: AppRoutes.agentDashboard,
        builder: (context, state) => const AgentDashboard(),
      ),
      GoRoute(
        path: AppRoutes.dataAcquisition,
        builder: (context, state) => const DataAcquisitionScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportPreview,
        builder: (context, state) => const ReportPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        builder: (context, state) => const MyReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.processingResult,
        builder: (context, state) {
          final reportId = state.uri.queryParameters['reportId'] ?? '';
          return ProcessingResultScreen(reportId: reportId);
        },
      ),

      // Volunteer routes
      GoRoute(
        path: AppRoutes.volunteerDashboard,
        builder: (context, state) => const VolunteerDashboard(),
      ),
      GoRoute(
        path: AppRoutes.verificationQueue,
        builder: (context, state) => const VerificationQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationDetail,
        builder: (context, state) {
          final reportId = state.uri.queryParameters['reportId'] ?? '';
          return VerificationDetailScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: AppRoutes.verificationHistory,
        builder: (context, state) => const VerificationHistoryScreen(),
      ),

      // NGO routes
      GoRoute(
        path: AppRoutes.ngoDashboard,
        builder: (context, state) => const NgoDashboard(),
      ),

      // Shared
      GoRoute(
        path: AppRoutes.reportDetail,
        builder: (context, state) {
          final reportId = state.uri.queryParameters['id'] ?? '';
          return ReportDetailScreen(reportId: reportId);
        },
      ),

      // Admin routes (no auth required)
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});

String _dashboardForRole(String role) {
  switch (role) {
    case UserRole.officer:
      return AppRoutes.officerDashboard;
    case UserRole.agent:
      return AppRoutes.agentDashboard;
    case UserRole.volunteer:
      return AppRoutes.volunteerDashboard;
    case UserRole.ngo:
      return AppRoutes.ngoDashboard;
    default:
      return AppRoutes.login;
  }
}
