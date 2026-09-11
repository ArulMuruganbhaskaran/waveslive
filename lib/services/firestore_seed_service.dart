import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../models/hazard_model.dart';

/// One-time Firestore seeder.
/// Checks a sentinel doc `meta/seed` before seeding.
/// Safe to call on every app start — will only seed once.
class FirestoreSeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> seedIfNeeded() async {
    final sentinel = await _db.collection('meta').doc('seed').get();
    if (sentinel.exists) return; // Already seeded

    await _seedAll();

    await _db.collection('meta').doc('seed').set({
      'seededAt': DateTime.now().toIso8601String(),
      'version': 1,
    });
  }

  Future<void> _seedAll() async {
    await _seedUsers();
    await _seedReportsAndHazards();
  }

  // ── Demo user accounts ────────────────────────────────────────────────────

  Future<void> _seedUsers() async {
    final accounts = [
      {
        'email': 'officer@waveslive.com',
        'password': 'demo123',
        'user': UserModel(
          id: '', // will be set to Firebase UID
          name: 'Arjun Krishnan',
          email: 'officer@waveslive.com',
          role: UserRole.officer,
          organisationId: 'org_cdma_001',
          organisationName: 'Coastal Disaster Management Authority',
          phone: '+91 98765 43210',
          isActive: true,
          createdAt: DateTime(2024, 1, 15),
        ),
      },
      {
        'email': 'agent@waveslive.com',
        'password': 'demo123',
        'user': UserModel(
          id: '',
          name: 'Priya Nair',
          email: 'agent@waveslive.com',
          role: UserRole.agent,
          organisationId: 'org_cdma_001',
          organisationName: 'Coastal Disaster Management Authority',
          phone: '+91 87654 32109',
          isActive: true,
          createdAt: DateTime(2024, 3, 10),
        ),
      },
      {
        'email': 'volunteer@waveslive.com',
        'password': 'demo123',
        'user': UserModel(
          id: '',
          name: 'Rajan Pillai',
          email: 'volunteer@waveslive.com',
          role: UserRole.volunteer,
          organisationId: 'org_volunteer_001',
          organisationName: 'Kerala Coastal Volunteers Network',
          phone: '+91 76543 21098',
          isActive: true,
          createdAt: DateTime(2024, 2, 20),
        ),
      },
      {
        'email': 'ngo@waveslive.com',
        'password': 'demo123',
        'user': UserModel(
          id: '',
          name: 'Meena Subramaniam',
          email: 'ngo@waveslive.com',
          role: UserRole.ngo,
          organisationId: 'org_ngo_001',
          organisationName: 'Sea Guard NGO',
          phone: '+91 65432 10987',
          isActive: true,
          createdAt: DateTime(2024, 1, 5),
        ),
      },
    ];

    for (final acc in accounts) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: acc['email'] as String,
          password: acc['password'] as String,
        );
        final uid = cred.user!.uid;
        final user = acc['user'] as UserModel;
        await _db.collection('users').doc(uid).set({
          ...user.toFirestore(),
          // Override id with the real Firebase UID
          'id': uid,
        });
      } catch (e) {
        // User already exists — skip
      }
    }

    // Sign out after seeding so the app starts at login
    await _auth.signOut();
  }

  // ── Demo reports / hazards / alerts / mitigation ──────────────────────────

  Future<void> _seedReportsAndHazards() async {
    const agentId = 'agent_seed'; // placeholder — real agent UID not known yet

    final now = DateTime.now();

    final reports = [
      ReportModel(
        id: 'rpt_seed_001',
        agentId: agentId,
        agentName: 'Priya Nair',
        imagePath:
            'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=800',
        latitude: 8.5241,
        longitude: 76.9366,
        locationName: 'Vizhinjam Coastal Area, Kerala',
        capturedAt: now.subtract(const Duration(hours: 3)),
        description:
            'Observed unusual wave patterns near the fishing harbour.',
        processingStatus: ProcessingStatus.completed,
        processingResult: ProcessingResultModel(
          reportId: 'rpt_seed_001',
          hazardDetected: true,
          hazardType: HazardType.coastalFlooding,
          confidenceScore: 0.87,
          severity: HazardSeverity.high,
          observation:
              'Significant wave height anomaly detected. Sea surface level appears elevated beyond normal tidal variation.',
          recommendation:
              'Coastal officers should immediately inspect the affected area.',
          processedAt: now.subtract(const Duration(hours: 2, minutes: 45)),
        ),
        verificationStatus: VerificationStatus.verified,
        incidentStatus: IncidentStatus.inProgress,
        verifications: [
          VerificationEntryModel(
            verifierId: 'vol_seed_001',
            verifierName: 'Rajan Pillai',
            verifierRole: UserRole.volunteer,
            result: VerificationResult.genuine,
            comment: 'Confirmed. Water levels are elevated.',
            verifiedAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        submittedAt: now.subtract(const Duration(hours: 3)),
        lastUpdatedAt: now.subtract(const Duration(hours: 1)),
      ),
      ReportModel(
        id: 'rpt_seed_002',
        agentId: agentId,
        agentName: 'Priya Nair',
        imagePath:
            'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=800',
        latitude: 8.4100,
        longitude: 77.0100,
        locationName: 'Poovar Beach, Kerala',
        capturedAt: now.subtract(const Duration(hours: 5)),
        description: 'Sea looks turbid. Heavy surge observed near the river mouth.',
        processingStatus: ProcessingStatus.completed,
        processingResult: ProcessingResultModel(
          reportId: 'rpt_seed_002',
          hazardDetected: true,
          hazardType: HazardType.stormSurge,
          confidenceScore: 0.79,
          severity: HazardSeverity.critical,
          observation: 'Storm surge indicators detected.',
          recommendation: 'CRITICAL: Initiate immediate coastal evacuation protocol.',
          processedAt: now.subtract(const Duration(hours: 4, minutes: 50)),
        ),
        verificationStatus: VerificationStatus.pending,
        incidentStatus: IncidentStatus.pending,
        verifications: [],
        submittedAt: now.subtract(const Duration(hours: 5)),
        lastUpdatedAt: now.subtract(const Duration(hours: 4, minutes: 50)),
      ),
    ];

    final batch = _db.batch();

    for (final r in reports) {
      batch.set(_db.collection('reports').doc(r.id), r.toFirestore());
    }

    // Hazards
    final hazard1 = HazardModel(
      id: 'haz_seed_001',
      reportId: 'rpt_seed_001',
      hazardType: HazardType.coastalFlooding,
      severity: HazardSeverity.high,
      latitude: 8.5241,
      longitude: 76.9366,
      locationName: 'Vizhinjam Coastal Area, Kerala',
      verificationStatus: VerificationStatus.verified,
      incidentStatus: IncidentStatus.inProgress,
      confidenceScore: 0.87,
      detectedAt: now.subtract(const Duration(hours: 2, minutes: 45)),
    );
    final hazard2 = HazardModel(
      id: 'haz_seed_002',
      reportId: 'rpt_seed_002',
      hazardType: HazardType.stormSurge,
      severity: HazardSeverity.critical,
      latitude: 8.4100,
      longitude: 77.0100,
      locationName: 'Poovar Beach, Kerala',
      verificationStatus: VerificationStatus.pending,
      incidentStatus: IncidentStatus.pending,
      confidenceScore: 0.79,
      detectedAt: now.subtract(const Duration(hours: 4, minutes: 50)),
    );

    batch.set(_db.collection('hazards').doc(hazard1.id), hazard1.toFirestore());
    batch.set(_db.collection('hazards').doc(hazard2.id), hazard2.toFirestore());

    // Alerts (target: officer — will be updated with real UID on first login)
    final alert1 = AlertModel(
      id: 'alt_seed_001',
      hazardId: hazard1.id,
      reportId: 'rpt_seed_001',
      hazardType: HazardType.coastalFlooding,
      level: AlertLevel.high,
      severity: HazardSeverity.high,
      locationName: 'Vizhinjam Coastal Area, Kerala',
      latitude: 8.5241,
      longitude: 76.9366,
      confidenceScore: 0.87,
      verificationStatus: VerificationStatus.verified,
      recommendedAction:
          'Inspect the affected coastal area and initiate precautionary safety measures.',
      createdAt: now.subtract(const Duration(hours: 2)),
      targetOfficerId: 'OFFICER_SEED',
    );
    final alert2 = AlertModel(
      id: 'alt_seed_002',
      hazardId: hazard2.id,
      reportId: 'rpt_seed_002',
      hazardType: HazardType.stormSurge,
      level: AlertLevel.critical,
      severity: HazardSeverity.critical,
      locationName: 'Poovar Beach, Kerala',
      latitude: 8.4100,
      longitude: 77.0100,
      confidenceScore: 0.79,
      verificationStatus: VerificationStatus.pending,
      recommendedAction:
          'CRITICAL: Activate coastal emergency protocol. Initiate mass evacuation.',
      createdAt: now.subtract(const Duration(hours: 4, minutes: 45)),
      targetOfficerId: 'OFFICER_SEED',
    );
    batch.set(_db.collection('alerts').doc(alert1.id), alert1.toFirestore());
    batch.set(_db.collection('alerts').doc(alert2.id), alert2.toFirestore());

    await batch.commit();
  }
}
