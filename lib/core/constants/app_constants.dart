/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'WavesLive';
  static const String appTagline = 'Coastal Hazard Detection & Monitoring';
  static const String appVersion = '1.0.0';

  // Report ID prefix
  static const String reportPrefix = 'RPT';
  static const String incidentPrefix = 'INC';
  static const String alertPrefix = 'ALT';
  static const String mitigationPrefix = 'MIT';

  // Confidence thresholds
  static const double highConfidenceThreshold = 0.80;
  static const double mediumConfidenceThreshold = 0.50;

  // Demo mode
  static const bool isDemoMode = true;
}

/// User roles
class UserRole {
  UserRole._();
  static const String admin = 'admin';
  static const String officer = 'officer';
  static const String agent = 'agent';
  static const String volunteer = 'volunteer';
  static const String ngo = 'ngo';

  static const List<String> manageable = [officer, agent, volunteer, ngo];

  static String displayName(String role) {
    switch (role) {
      case admin:
        return 'Master Admin';
      case officer:
        return 'Coastal Officer';
      case agent:
        return 'Local Agent';
      case volunteer:
        return 'Volunteer';
      case ngo:
        return 'NGO Representative';
      default:
        return 'Unknown';
    }
  }
}

/// Hazard severity levels
class HazardSeverity {
  HazardSeverity._();
  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';
}

/// Hazard types
class HazardType {
  HazardType._();
  static const String flashFlood = 'Flash Flood Risk';
  static const String coastalFlooding = 'Coastal Flooding';
  static const String stormSurge = 'Storm Surge';
  static const String highWaves = 'High Waves';
  static const String cyclone = 'Cyclone-Related Conditions';
  static const String abnormalSea = 'Abnormal Sea Conditions';
  static const String other = 'Other Coastal Hazard';
  static const String none = 'No Hazard Detected';

  static const List<String> all = [
    flashFlood,
    coastalFlooding,
    stormSurge,
    highWaves,
    cyclone,
    abnormalSea,
    other,
  ];
}

/// Incident/Report status
class IncidentStatus {
  IncidentStatus._();
  static const String pending = 'PENDING';
  static const String inProgress = 'IN_PROGRESS';
  static const String mitigated = 'MITIGATED';
  static const String resolved = 'RESOLVED';

  static String displayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case inProgress:
        return 'In Progress';
      case mitigated:
        return 'Mitigated';
      case resolved:
        return 'Resolved';
      default:
        return status;
    }
  }
}

/// Verification status
class VerificationStatus {
  VerificationStatus._();
  static const String unverified = 'UNVERIFIED';
  static const String verified = 'VERIFIED';
  static const String suspicious = 'SUSPICIOUS';
  static const String rejected = 'REJECTED';
  static const String pending = 'PENDING';
}

/// Verification result options
class VerificationResult {
  VerificationResult._();
  static const String genuine = 'GENUINE';
  static const String suspicious = 'SUSPICIOUS';
  static const String falsified = 'FALSE';
}

/// Alert levels
class AlertLevel {
  AlertLevel._();
  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';
}

/// Processing status
class ProcessingStatus {
  ProcessingStatus._();
  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String completed = 'COMPLETED';
  static const String failed = 'FAILED';
}
