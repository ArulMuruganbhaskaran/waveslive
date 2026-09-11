import 'dart:math';
import '../models/report_model.dart';
import '../core/constants/app_constants.dart';
import 'model_processing_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock AI / Model Processing Service  (v2 — Weighted, Realistic Detection)
// ─────────────────────────────────────────────────────────────────────────────
//
// Replace with actual ML model / REST API integration when ready.
// Interface: [ModelProcessingService]
//
// Improvements over v1:
//  • Weighted scenario selection — real-world hazard distribution
//  • Gaussian-noise confidence scores  (±8%) for realism
//  • Time-of-day factor: night images → elevated storm/abnormal weights
//  • GPS location factor: Kerala/Tamil Nadu coastal box → elevated cyclone risk
//  • "No Hazard Detected" included at realistic ~25-30% baseline probability
//  • Realistic processing delay (Gaussian-distributed 1.5 – 4.5 s)
//  • Failed-processing path for very low image quality signals
// ─────────────────────────────────────────────────────────────────────────────

class MockModelProcessingService implements ModelProcessingService {
  final _random = Random();

  // ─────────────────────────────────────────────────────
  // Scenario catalogue — each entry carries a base weight
  // ─────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _scenarios = [
    // ── Hazard scenarios ─────────────────────────────
    {
      'weight': 0.10, // 10 % base probability
      'hazardDetected': true,
      'hazardType': HazardType.coastalFlooding,
      'confidence': 0.87,
      'severity': HazardSeverity.high,
      'observation':
          'Significant wave height anomaly detected. Sea surface level appears '
          'elevated beyond normal tidal variation. Water is encroaching on '
          'coastal land boundary.',
      'recommendation':
          'Coastal officers should immediately inspect the affected area. '
          'Initiate precautionary evacuation measures for low-lying coastal '
          'settlements within 500 m of the shoreline.',
    },
    {
      'weight': 0.12,
      'hazardDetected': true,
      'hazardType': HazardType.highWaves,
      'confidence': 0.92,
      'severity': HazardSeverity.high,
      'observation':
          'Unusual wave patterns detected with estimated wave height of '
          '4–6 metres. Wave period and frequency indicate potential '
          'storm-driven surge conditions.',
      'recommendation':
          'Issue immediate advisory to fishing communities. Prohibit marine '
          'activity within 3 km of the coast. Alert emergency response teams.',
    },
    {
      'weight': 0.08,
      'hazardDetected': true,
      'hazardType': HazardType.stormSurge,
      'confidence': 0.79,
      'severity': HazardSeverity.critical,
      'observation':
          'Storm surge indicators detected. Sea surface exhibits characteristic '
          'turbulence patterns associated with low-pressure system activity. '
          'Foam and debris accumulation observed.',
      'recommendation':
          'CRITICAL: Initiate immediate coastal evacuation protocol. Coordinate '
          'with district administration. Deploy emergency response units. Issue '
          'public warning via all available channels.',
    },
    {
      'weight': 0.14,
      'hazardDetected': true,
      'hazardType': HazardType.abnormalSea,
      'confidence': 0.73,
      'severity': HazardSeverity.medium,
      'observation':
          'Abnormal sea conditions detected. Sea colour appears turbid with '
          'unusual sediment patterns. Minor wave anomalies observed compared '
          'to baseline conditions.',
      'recommendation':
          'Monitor the area for the next 6 hours. Restrict fishing activities '
          'as a precautionary measure. Conduct ground-level verification.',
    },
    {
      'weight': 0.06,
      'hazardDetected': true,
      'hazardType': HazardType.cyclone,
      'confidence': 0.95,
      'severity': HazardSeverity.critical,
      'observation':
          'Cyclone precursor indicators identified. Atmospheric and sea surface '
          'conditions consistent with pre-cyclone patterns. Spiral cloud '
          'formation and sea surface temperature elevation observed.',
      'recommendation':
          'CRITICAL: Activate cyclone emergency protocol immediately. Coordinate '
          'with meteorological department. Initiate mass evacuation of coastal '
          'zones. Establish emergency shelters.',
    },
    {
      'weight': 0.09,
      'hazardDetected': true,
      'hazardType': HazardType.flashFlood,
      'confidence': 0.81,
      'severity': HazardSeverity.high,
      'observation':
          'Flash flood risk conditions detected. Coastal water levels rising '
          'rapidly. Backwater flooding indicators present in adjacent '
          'low-lying areas.',
      'recommendation':
          'Alert flood management authorities. Deploy water level monitoring '
          'teams. Initiate precautionary measures for flood-prone coastal areas.',
    },
    {
      'weight': 0.07,
      'hazardDetected': true,
      'hazardType': HazardType.other,
      'confidence': 0.68,
      'severity': HazardSeverity.medium,
      'observation':
          'Unclassified coastal hazard indicators detected. Sea surface shows '
          'irregular patterns that do not match known hazard signatures but '
          'deviate significantly from baseline.',
      'recommendation':
          'Request expert review. Do not dismiss. Deploy field verification '
          'team within 2 hours.',
    },
    // ── No Hazard scenario ────────────────────────────
    {
      'weight': 0.34, // ~34% baseline — sea is calm most of the time
      'hazardDetected': false,
      'hazardType': HazardType.none,
      'confidence': 0.91,
      'severity': HazardSeverity.low,
      'observation':
          'Sea conditions appear normal. Wave patterns are within seasonal '
          'norms. No significant anomalies detected in the captured image.',
      'recommendation':
          'No immediate action required. Continue routine monitoring as per '
          'standard protocol.',
    },
  ];

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<ProcessingResultModel> analyzeImage({
    required String reportId,
    required String imagePath,
    required double latitude,
    required double longitude,
  }) async {
    // Gaussian-distributed delay: mean ~2.5 s, clipped to [1.5, 4.5] s
    final delayMs = _gaussianClipped(mean: 2500, std: 600, min: 1500, max: 4500);
    await Future.delayed(Duration(milliseconds: delayMs));

    // Build adjusted weights based on context
    final weights = _buildWeights(latitude: latitude, longitude: longitude);

    // Weighted random selection
    final selectedIndex = _weightedRandom(weights);
    final scenario = _scenarios[selectedIndex];

    // Apply Gaussian noise to confidence score (±8 %)
    final baseConfidence = scenario['confidence'] as double;
    final noise = _gaussianNoise(std: 0.04); // ±4 % (1 std) = ±8% (2 std)
    final finalConfidence = (baseConfidence + noise).clamp(0.50, 0.99);

    return ProcessingResultModel(
      reportId: reportId,
      hazardDetected: scenario['hazardDetected'] as bool,
      hazardType: scenario['hazardType'] as String,
      confidenceScore: finalConfidence,
      severity: scenario['severity'] as String,
      observation: scenario['observation'] as String,
      recommendation: scenario['recommendation'] as String,
      processedAt: DateTime.now(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Weight computation
  // ──────────────────────────────────────────────────────────────────────────

  /// Build a weight list (one per scenario) adjusted for time-of-day and GPS.
  List<double> _buildWeights({
    required double latitude,
    required double longitude,
  }) {
    final hour = DateTime.now().hour;

    // Night-time factor (20:00–05:00): elevate storm/surge/cyclone
    final isNight = hour >= 20 || hour <= 5;

    // Kerala / Tamil Nadu coastal box:  lat 8–13, lon 76–80
    final isKeralaCoast =
        latitude >= 8.0 && latitude <= 13.5 &&
        longitude >= 76.0 && longitude <= 80.5;

    // Monsoon months (June–September in India)
    final month = DateTime.now().month;
    final isMonsoon = month >= 6 && month <= 9;

    final weights = <double>[];

    for (int i = 0; i < _scenarios.length; i++) {
      double w = _scenarios[i]['weight'] as double;
      final hazardType = _scenarios[i]['hazardType'] as String;

      // Night boost for storm surge, cyclone, high waves
      if (isNight) {
        if (hazardType == HazardType.stormSurge) w *= 1.4;
        if (hazardType == HazardType.highWaves) w *= 1.3;
        if (hazardType == HazardType.cyclone) w *= 1.2;
        // Calm sea slightly less likely at night
        if (hazardType == HazardType.none) w *= 0.85;
      }

      // Kerala coastal boost for cyclone, coastal flooding
      if (isKeralaCoast) {
        if (hazardType == HazardType.cyclone) w *= 1.35;
        if (hazardType == HazardType.coastalFlooding) w *= 1.2;
        if (hazardType == HazardType.flashFlood) w *= 1.15;
      }

      // Monsoon season: elevate flood, high-wave, storm-surge
      if (isMonsoon) {
        if (hazardType == HazardType.flashFlood) w *= 1.3;
        if (hazardType == HazardType.highWaves) w *= 1.2;
        if (hazardType == HazardType.stormSurge) w *= 1.2;
        if (hazardType == HazardType.none) w *= 0.80;
      }

      // Add small random noise (±5%) so results aren't perfectly deterministic
      w *= 0.95 + _random.nextDouble() * 0.10;

      weights.add(w.clamp(0.001, 10.0));
    }

    return weights;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Statistical helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Weighted random index selection using provided weights.
  int _weightedRandom(List<double> weights) {
    final total = weights.fold(0.0, (a, b) => a + b);
    final roll = _random.nextDouble() * total;
    double cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (roll <= cumulative) return i;
    }
    return weights.length - 1;
  }

  /// Box-Muller transform to generate normally distributed noise.
  double _gaussianNoise({required double std}) {
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final z = sqrt(-2.0 * log(u1 + 1e-10)) * cos(2.0 * pi * u2);
    return z * std;
  }

  /// Gaussian-distributed integer, clipped to [min, max].
  int _gaussianClipped({
    required double mean,
    required double std,
    required int min,
    required int max,
  }) {
    final value = mean + _gaussianNoise(std: std);
    return value.clamp(min.toDouble(), max.toDouble()).toInt();
  }
}
