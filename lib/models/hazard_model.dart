import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HazardModel
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Firestore serialization ───────────────────────────────────────────────

  factory HazardModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return HazardModel(
      id: doc.id,
      reportId: d['reportId'] ?? '',
      hazardType: d['hazardType'] ?? HazardType.other,
      severity: d['severity'] ?? HazardSeverity.low,
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: d['locationName'],
      verificationStatus:
          d['verificationStatus'] ?? VerificationStatus.pending,
      incidentStatus: d['incidentStatus'] ?? IncidentStatus.pending,
      confidenceScore: (d['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      detectedAt: _parseDate(d['detectedAt']),
      resolvedAt:
          d['resolvedAt'] != null ? _parseDate(d['resolvedAt']) : null,
      assignedOfficerId: d['assignedOfficerId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reportId': reportId,
        'hazardType': hazardType,
        'severity': severity,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'verificationStatus': verificationStatus,
        'incidentStatus': incidentStatus,
        'confidenceScore': confidenceScore,
        'detectedAt': detectedAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'assignedOfficerId': assignedOfficerId,
      };

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AlertModel
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Firestore serialization ───────────────────────────────────────────────

  factory AlertModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AlertModel(
      id: doc.id,
      hazardId: d['hazardId'] ?? '',
      reportId: d['reportId'] ?? '',
      hazardType: d['hazardType'] ?? HazardType.other,
      level: d['level'] ?? AlertLevel.info,
      severity: d['severity'] ?? HazardSeverity.low,
      locationName: d['locationName'],
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (d['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      verificationStatus:
          d['verificationStatus'] ?? VerificationStatus.pending,
      recommendedAction: d['recommendedAction'] ?? '',
      isRead: d['isRead'] as bool? ?? false,
      createdAt: _parseDate(d['createdAt']),
      targetOfficerId: d['targetOfficerId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hazardId': hazardId,
        'reportId': reportId,
        'hazardType': hazardType,
        'level': level,
        'severity': severity,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'confidenceScore': confidenceScore,
        'verificationStatus': verificationStatus,
        'recommendedAction': recommendedAction,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'targetOfficerId': targetOfficerId,
      };

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MitigationActionModel
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Firestore serialization ───────────────────────────────────────────────

  factory MitigationActionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MitigationActionModel(
      id: doc.id,
      hazardId: d['hazardId'] ?? '',
      reportId: d['reportId'] ?? '',
      hazardType: d['hazardType'] ?? HazardType.other,
      severity: d['severity'] ?? HazardSeverity.low,
      actionTaken: d['actionTaken'] ?? '',
      assignedTeam: d['assignedTeam'] ?? '',
      safetyInstructions: d['safetyInstructions'] ?? '',
      status: d['status'] ?? IncidentStatus.pending,
      officerId: d['officerId'] ?? '',
      officerName: d['officerName'] ?? '',
      createdAt: _parseDate(d['createdAt']),
      lastUpdatedAt:
          d['lastUpdatedAt'] != null ? _parseDate(d['lastUpdatedAt']) : null,
      completedAt:
          d['completedAt'] != null ? _parseDate(d['completedAt']) : null,
      statusHistory: (d['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => MitigationStatusUpdateModel.fromMap(
              Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hazardId': hazardId,
        'reportId': reportId,
        'hazardType': hazardType,
        'severity': severity,
        'actionTaken': actionTaken,
        'assignedTeam': assignedTeam,
        'safetyInstructions': safetyInstructions,
        'status': status,
        'officerId': officerId,
        'officerName': officerName,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      };

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MitigationStatusUpdateModel
// ─────────────────────────────────────────────────────────────────────────────

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

  factory MitigationStatusUpdateModel.fromMap(Map<String, dynamic> m) =>
      MitigationStatusUpdateModel(
        status: m['status'] ?? '',
        note: m['note'] ?? '',
        updatedById: m['updatedById'] ?? '',
        updatedAt: m['updatedAt'] is Timestamp
            ? (m['updatedAt'] as Timestamp).toDate()
            : DateTime.parse(
                m['updatedAt'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toMap() => {
        'status': status,
        'note': note,
        'updatedById': updatedById,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
