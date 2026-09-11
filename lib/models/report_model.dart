import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Represents a sea-condition report submitted by a local agent
class ReportModel {
  final String id;
  final String agentId;
  final String agentName;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String? locationName;
  final DateTime capturedAt;
  final String? description;
  final String processingStatus;
  final ProcessingResultModel? processingResult;
  final String verificationStatus;
  final String incidentStatus;
  final List<VerificationEntryModel> verifications;
  final DateTime submittedAt;
  final DateTime? lastUpdatedAt;

  const ReportModel({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.capturedAt,
    this.description,
    this.processingStatus = ProcessingStatus.pending,
    this.processingResult,
    this.verificationStatus = VerificationStatus.pending,
    this.incidentStatus = IncidentStatus.pending,
    this.verifications = const [],
    required this.submittedAt,
    this.lastUpdatedAt,
  });

  String get displayId =>
      '${AppConstants.reportPrefix}-${id.substring(0, 6).toUpperCase()}';

  bool get hasHazard =>
      processingResult != null && processingResult!.hazardDetected;

  ReportModel copyWith({
    String? processingStatus,
    ProcessingResultModel? processingResult,
    String? verificationStatus,
    String? incidentStatus,
    List<VerificationEntryModel>? verifications,
    DateTime? lastUpdatedAt,
  }) {
    return ReportModel(
      id: id,
      agentId: agentId,
      agentName: agentName,
      imagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      capturedAt: capturedAt,
      description: description,
      processingStatus: processingStatus ?? this.processingStatus,
      processingResult: processingResult ?? this.processingResult,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      incidentStatus: incidentStatus ?? this.incidentStatus,
      verifications: verifications ?? this.verifications,
      submittedAt: submittedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  factory ReportModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ReportModel(
      id: doc.id,
      agentId: d['agentId'] ?? '',
      agentName: d['agentName'] ?? '',
      imagePath: d['imagePath'] ?? '',
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: d['locationName'],
      capturedAt: _parseDate(d['capturedAt']),
      description: d['description'],
      processingStatus: d['processingStatus'] ?? ProcessingStatus.pending,
      processingResult: d['processingResult'] != null
          ? ProcessingResultModel.fromMap(
              Map<String, dynamic>.from(d['processingResult']))
          : null,
      verificationStatus:
          d['verificationStatus'] ?? VerificationStatus.pending,
      incidentStatus: d['incidentStatus'] ?? IncidentStatus.pending,
      verifications: (d['verifications'] as List<dynamic>? ?? [])
          .map((v) =>
              VerificationEntryModel.fromMap(Map<String, dynamic>.from(v)))
          .toList(),
      submittedAt: _parseDate(d['submittedAt']),
      lastUpdatedAt:
          d['lastUpdatedAt'] != null ? _parseDate(d['lastUpdatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'agentId': agentId,
        'agentName': agentName,
        'imagePath': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'capturedAt': capturedAt.toIso8601String(),
        'description': description,
        'processingStatus': processingStatus,
        'processingResult': processingResult?.toMap(),
        'verificationStatus': verificationStatus,
        'incidentStatus': incidentStatus,
        'verifications': verifications.map((v) => v.toMap()).toList(),
        'submittedAt': submittedAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      };

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Result from AI/model processing of a sea image
class ProcessingResultModel {
  final String reportId;
  final bool hazardDetected;
  final String hazardType;
  final double confidenceScore;
  final String severity;
  final String observation;
  final String recommendation;
  final DateTime processedAt;

  const ProcessingResultModel({
    required this.reportId,
    required this.hazardDetected,
    required this.hazardType,
    required this.confidenceScore,
    required this.severity,
    required this.observation,
    required this.recommendation,
    required this.processedAt,
  });

  String get confidencePercentage =>
      '${(confidenceScore * 100).toStringAsFixed(0)}%';

  factory ProcessingResultModel.fromMap(Map<String, dynamic> m) =>
      ProcessingResultModel(
        reportId: m['reportId'] ?? '',
        hazardDetected: m['hazardDetected'] as bool? ?? false,
        hazardType: m['hazardType'] ?? HazardType.none,
        confidenceScore: (m['confidenceScore'] as num?)?.toDouble() ?? 0.0,
        severity: m['severity'] ?? HazardSeverity.low,
        observation: m['observation'] ?? '',
        recommendation: m['recommendation'] ?? '',
        processedAt: m['processedAt'] is Timestamp
            ? (m['processedAt'] as Timestamp).toDate()
            : DateTime.parse(
                m['processedAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'reportId': reportId,
        'hazardDetected': hazardDetected,
        'hazardType': hazardType,
        'confidenceScore': confidenceScore,
        'severity': severity,
        'observation': observation,
        'recommendation': recommendation,
        'processedAt': processedAt.toIso8601String(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// A single verifier's verification entry
class VerificationEntryModel {
  final String verifierId;
  final String verifierName;
  final String verifierRole;
  final String result;
  final String? comment;
  final DateTime verifiedAt;

  const VerificationEntryModel({
    required this.verifierId,
    required this.verifierName,
    required this.verifierRole,
    required this.result,
    this.comment,
    required this.verifiedAt,
  });

  factory VerificationEntryModel.fromMap(Map<String, dynamic> m) =>
      VerificationEntryModel(
        verifierId: m['verifierId'] ?? '',
        verifierName: m['verifierName'] ?? '',
        verifierRole: m['verifierRole'] ?? '',
        result: m['result'] ?? VerificationResult.genuine,
        comment: m['comment'],
        verifiedAt: m['verifiedAt'] is Timestamp
            ? (m['verifiedAt'] as Timestamp).toDate()
            : DateTime.parse(
                m['verifiedAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'verifierId': verifierId,
        'verifierName': verifierName,
        'verifierRole': verifierRole,
        'result': result,
        'comment': comment,
        'verifiedAt': verifiedAt.toIso8601String(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────

/// Summary of all verifications for a report
class VerificationSummaryModel {
  final int genuineCount;
  final int suspiciousCount;
  final int falseCount;
  final String overallStatus;

  const VerificationSummaryModel({
    required this.genuineCount,
    required this.suspiciousCount,
    required this.falseCount,
    required this.overallStatus,
  });

  int get totalCount => genuineCount + suspiciousCount + falseCount;
}
