import '../core/constants/app_constants.dart';

/// Represents an active hazard incident
class HazardModel {
  final String id;
  final String reportId;
  final String hazardType;
  final String severity;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String verificationStatus;
  final String incidentStatus;
  final double confidenceScore;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final String? assignedOfficerId;

  const HazardModel({
    required this.id,
    required this.reportId,
    required this.hazardType,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.verificationStatus,
    required this.incidentStatus,
    required this.confidenceScore,
    required this.detectedAt,
    this.resolvedAt,
    this.assignedOfficerId,
  });

  String get displayId =>
      '${AppConstants.incidentPrefix}-${id.substring(0, 6).toUpperCase()}';

  HazardModel copyWith({
    String? incidentStatus,
    String? assignedOfficerId,
    DateTime? resolvedAt,
  }) {
    return HazardModel(
      id: id,
      reportId: reportId,
      hazardType: hazardType,
      severity: severity,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      verificationStatus: verificationStatus,
      incidentStatus: incidentStatus ?? this.incidentStatus,
      confidenceScore: confidenceScore,
      detectedAt: detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
    );
  }
}

/// Represents an alert sent to coastal officers
class AlertModel {
  final String id;
  final String hazardId;
  final String reportId;
  final String hazardType;
  final String level;
  final String severity;
  final String? locationName;
  final double latitude;
  final double longitude;
  final double confidenceScore;
  final String verificationStatus;
  final String recommendedAction;
  final bool isRead;
  final DateTime createdAt;
  final String? targetOfficerId;

  const AlertModel({
    required this.id,
    required this.hazardId,
    required this.reportId,
    required this.hazardType,
    required this.level,
    required this.severity,
    this.locationName,
    required this.latitude,
    required this.longitude,
    required this.confidenceScore,
    required this.verificationStatus,
    required this.recommendedAction,
    this.isRead = false,
    required this.createdAt,
    this.targetOfficerId,
  });

  String get displayId =>
      '${AppConstants.alertPrefix}-${id.substring(0, 6).toUpperCase()}';

  AlertModel copyWith({bool? isRead}) {
    return AlertModel(
      id: id,
      hazardId: hazardId,
      reportId: reportId,
      hazardType: hazardType,
      level: level,
      severity: severity,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      confidenceScore: confidenceScore,
      verificationStatus: verificationStatus,
      recommendedAction: recommendedAction,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      targetOfficerId: targetOfficerId,
    );
  }
}

/// Represents a mitigation action taken by a coastal officer
class MitigationActionModel {
  final String id;
  final String hazardId;
  final String reportId;
  final String hazardType;
  final String severity;
  final String actionTaken;
  final String assignedTeam;
  final String safetyInstructions;
  final String status;
  final String officerId;
  final String officerName;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final DateTime? completedAt;
  final List<MitigationStatusUpdateModel> statusHistory;

  const MitigationActionModel({
    required this.id,
    required this.hazardId,
    required this.reportId,
    required this.hazardType,
    required this.severity,
    required this.actionTaken,
    required this.assignedTeam,
    required this.safetyInstructions,
    required this.status,
    required this.officerId,
    required this.officerName,
    required this.createdAt,
    this.lastUpdatedAt,
    this.completedAt,
    this.statusHistory = const [],
  });

  String get displayId =>
      '${AppConstants.mitigationPrefix}-${id.substring(0, 6).toUpperCase()}';

  MitigationActionModel copyWith({
    String? status,
    String? actionTaken,
    List<MitigationStatusUpdateModel>? statusHistory,
    DateTime? lastUpdatedAt,
    DateTime? completedAt,
  }) {
    return MitigationActionModel(
      id: id,
      hazardId: hazardId,
      reportId: reportId,
      hazardType: hazardType,
      severity: severity,
      actionTaken: actionTaken ?? this.actionTaken,
      assignedTeam: assignedTeam,
      safetyInstructions: safetyInstructions,
      status: status ?? this.status,
      officerId: officerId,
      officerName: officerName,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      completedAt: completedAt ?? this.completedAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}

/// A single status update in a mitigation action's history
class MitigationStatusUpdateModel {
  final String status;
  final String note;
  final String updatedById;
  final DateTime updatedAt;

  const MitigationStatusUpdateModel({
    required this.status,
    required this.note,
    required this.updatedById,
    required this.updatedAt,
  });
}
