import '../models/report_model.dart';

/// Abstract interface for model processing service
/// Can be replaced with a real ML model / REST API
abstract class ModelProcessingService {
  /// Analyze a sea image and return a processing result
  Future<ProcessingResultModel> analyzeImage({
    required String reportId,
    required String imagePath,
    required double latitude,
    required double longitude,
  });
}
