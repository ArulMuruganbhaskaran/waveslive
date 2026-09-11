import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/hazard_model.dart';
import '../core/constants/app_constants.dart';

const _uuid = Uuid();

/// Central data store for mock services (simulates Firestore)
class MockDataStore {
  MockDataStore._();
  static final MockDataStore instance = MockDataStore._();

  // Shared collections
  final List<ReportModel> reports = [];
  final List<HazardModel> hazards = [];
  final List<AlertModel> alerts = [];
  final List<MitigationActionModel> mitigationActions = [];

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _seedDemoData();
  }

  void _seedDemoData() {
    // Create demo reports with various states
    final demoReports = [
      ReportModel(
        id: _uuid.v4(),
        agentId: 'usr_agent_001',
        agentName: 'Priya Nair',
        imagePath: 'assets/images/sea_demo.jpg',
        latitude: 8.5241,
        longitude: 76.9366,
        locationName: 'Vizhinjam Coastal Area, Kerala',
        capturedAt: DateTime.now().subtract(const Duration(hours: 3)),
        description:
            'Observed unusual wave patterns near the fishing harbour. Waves appeared rougher than usual for this time of day.',
        processingStatus: ProcessingStatus.completed,
        processingResult: ProcessingResultModel(
          reportId: 'demo_rpt_1',
          hazardDetected: true,
          hazardType: HazardType.coastalFlooding,
          confidenceScore: 0.87,
          severity: HazardSeverity.high,
          observation:
              'Significant wave height anomaly detected. Sea surface level appears elevated beyond normal tidal variation.',
          recommendation:
              'Coastal officers should immediately inspect the affected area. Initiate precautionary evacuation measures.',
          processedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        ),
        verificationStatus: VerificationStatus.verified,
        incidentStatus: IncidentStatus.inProgress,
        verifications: [
          VerificationEntryModel(
            verifierId: 'usr_volunteer_001',
            verifierName: 'Rajan Pillai',
            verifierRole: UserRole.volunteer,
            result: VerificationResult.genuine,
            comment: 'Confirmed. I visited the site. Water levels are elevated.',
            verifiedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          VerificationEntryModel(
            verifierId: 'usr_ngo_001',
            verifierName: 'Meena Subramaniam',
            verifierRole: UserRole.ngo,
            result: VerificationResult.genuine,
            comment: 'Our field team confirms coastal flooding signs.',
            verifiedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          ),
        ],
        submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
        lastUpdatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ReportModel(
        id: _uuid.v4(),
        agentId: 'usr_agent_001',
        agentName: 'Priya Nair',
        imagePath: 'assets/images/sea_demo.jpg',
        latitude: 8.4100,
        longitude: 77.0100,
        locationName: 'Poovar Beach, Kerala',
        capturedAt: DateTime.now().subtract(const Duration(hours: 5)),
        description: 'Sea looks turbid. Heavy surge observed near the river mouth.',
        processingStatus: ProcessingStatus.completed,
        processingResult: ProcessingResultModel(
          reportId: 'demo_rpt_2',
          hazardDetected: true,
          hazardType: HazardType.stormSurge,
          confidenceScore: 0.79,
          severity: HazardSeverity.critical,
          observation:
              'Storm surge indicators detected. Sea surface exhibits turbulence patterns.',
          recommendation:
              'CRITICAL: Initiate immediate coastal evacuation protocol.',
          processedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)),
        ),
        verificationStatus: VerificationStatus.pending,
        incidentStatus: IncidentStatus.pending,
        verifications: [],
        submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
        lastUpdatedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)),
      ),
      ReportModel(
        id: _uuid.v4(),
        agentId: 'usr_agent_001',
        agentName: 'Priya Nair',
        imagePath: 'assets/images/sea_demo.jpg',
        latitude: 8.5900,
        longitude: 76.8800,
        locationName: 'Kovalam Beach, Kerala',
        capturedAt: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Routine morning observation. Sea appears calm.',
        processingStatus: ProcessingStatus.completed,
        processingResult: ProcessingResultModel(
          reportId: 'demo_rpt_3',
          hazardDetected: false,
          hazardType: HazardType.none,
          confidenceScore: 0.94,
          severity: HazardSeverity.low,
          observation:
              'Sea conditions appear normal. Wave patterns are within seasonal norms.',
          recommendation: 'No immediate action required. Continue routine monitoring.',
          processedAt: DateTime.now().subtract(const Duration(days: 1, minutes: -10)),
        ),
        verificationStatus: VerificationStatus.verified,
        incidentStatus: IncidentStatus.resolved,
        verifications: [
          VerificationEntryModel(
            verifierId: 'usr_volunteer_001',
            verifierName: 'Rajan Pillai',
            verifierRole: UserRole.volunteer,
            result: VerificationResult.genuine,
            comment: 'Confirmed no hazard. Sea looks fine.',
            verifiedAt: DateTime.now().subtract(const Duration(hours: 22)),
          ),
        ],
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
        lastUpdatedAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
      ReportModel(
        id: _uuid.v4(),
        agentId: 'usr_agent_001',
        agentName: 'Priya Nair',
        imagePath: 'assets/images/sea_demo.jpg',
        latitude: 8.4750,
        longitude: 76.9500,
        locationName: 'Anchuthengu, Kerala',
        capturedAt: DateTime.now().subtract(const Duration(hours: 1)),
        description: 'Possible cyclone precursor observed. Sky looks dark.',
        processingStatus: ProcessingStatus.processing,
        processingResult: null,
        verificationStatus: VerificationStatus.pending,
        incidentStatus: IncidentStatus.pending,
        verifications: [],
        submittedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    reports.addAll(demoReports);

    // Create demo hazards from completed reports
    final hazard1 = HazardModel(
      id: _uuid.v4(),
      reportId: demoReports[0].id,
      hazardType: HazardType.coastalFlooding,
      severity: HazardSeverity.high,
      latitude: 8.5241,
      longitude: 76.9366,
      locationName: 'Vizhinjam Coastal Area, Kerala',
      verificationStatus: VerificationStatus.verified,
      incidentStatus: IncidentStatus.inProgress,
      confidenceScore: 0.87,
      detectedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      assignedOfficerId: 'usr_officer_001',
    );

    final hazard2 = HazardModel(
      id: _uuid.v4(),
      reportId: demoReports[1].id,
      hazardType: HazardType.stormSurge,
      severity: HazardSeverity.critical,
      latitude: 8.4100,
      longitude: 77.0100,
      locationName: 'Poovar Beach, Kerala',
      verificationStatus: VerificationStatus.pending,
      incidentStatus: IncidentStatus.pending,
      confidenceScore: 0.79,
      detectedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)),
    );

    hazards.addAll([hazard1, hazard2]);

    // Create demo alerts
    alerts.addAll([
      AlertModel(
        id: _uuid.v4(),
        hazardId: hazard1.id,
        reportId: demoReports[0].id,
        hazardType: HazardType.coastalFlooding,
        level: AlertLevel.high,
        severity: HazardSeverity.high,
        locationName: 'Vizhinjam Coastal Area, Kerala',
        latitude: 8.5241,
        longitude: 76.9366,
        confidenceScore: 0.87,
        verificationStatus: VerificationStatus.verified,
        recommendedAction:
            'Inspect the affected coastal area and initiate precautionary safety measures. Coordinate with local administration for possible evacuation.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        targetOfficerId: 'usr_officer_001',
      ),
      AlertModel(
        id: _uuid.v4(),
        hazardId: hazard2.id,
        reportId: demoReports[1].id,
        hazardType: HazardType.stormSurge,
        level: AlertLevel.critical,
        severity: HazardSeverity.critical,
        locationName: 'Poovar Beach, Kerala',
        latitude: 8.4100,
        longitude: 77.0100,
        confidenceScore: 0.79,
        verificationStatus: VerificationStatus.pending,
        recommendedAction:
            'CRITICAL: Activate coastal emergency protocol. Initiate mass evacuation of coastal zones within 1km. Establish emergency shelters.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 45)),
        targetOfficerId: 'usr_officer_001',
      ),
    ]);

    // Create a demo mitigation action
    mitigationActions.add(
      MitigationActionModel(
        id: _uuid.v4(),
        hazardId: hazard1.id,
        reportId: demoReports[0].id,
        hazardType: HazardType.coastalFlooding,
        severity: HazardSeverity.high,
        actionTaken:
            'Coastal inspection initiated. Emergency response team deployed to the site. Barricades placed along flooded coastal road.',
        assignedTeam: 'Emergency Response Team Alpha',
        safetyInstructions:
            'Move vulnerable people away from the affected coastal area. Prohibit fishing and marine activities within 2km. Set up relief camps at higher ground locations.',
        status: IncidentStatus.inProgress,
        officerId: 'usr_officer_001',
        officerName: 'Arjun Krishnan',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        statusHistory: [
          MitigationStatusUpdateModel(
            status: IncidentStatus.pending,
            note: 'Mitigation action created.',
            updatedById: 'usr_officer_001',
            updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          ),
          MitigationStatusUpdateModel(
            status: IncidentStatus.inProgress,
            note:
                'Emergency response team dispatched. On-site inspection in progress.',
            updatedById: 'usr_officer_001',
            updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
    );
  }
}
