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

  String get displayId => '${AppConstants.reportPrefix}-${id.substring(0, 6).toUpperCase()}';

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
}

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
}

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
}

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
