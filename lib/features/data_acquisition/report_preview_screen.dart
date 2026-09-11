import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../services/image_validation_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/image_file_helper.dart';
import 'data_acquisition_screen.dart';

class ReportPreviewScreen extends ConsumerStatefulWidget {
  const ReportPreviewScreen({super.key});

  @override
  ConsumerState<ReportPreviewScreen> createState() =>
      _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends ConsumerState<ReportPreviewScreen> {
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final captureState = ref.read(captureStateProvider);
    final user = ref.read(currentUserProvider);

    if (captureState.image == null || user == null) return;

    // ── Safety-net validation check (defense in depth) ────────────────────
    // The primary check already ran in DataAcquisitionScreen.
    // This secondary check guards against any edge-case bypass.
    setState(() => _isSubmitting = true);

    try {
      final validator = ref.read(imageValidationServiceProvider);
      final validation = await validator.validate(captureState.image!);

      if (!mounted) return;

      if (validation is ImageValidationFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${validation.icon} ${validation.userMessage}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }
    } catch (_) {
      // If validation itself errors, allow submission (fail open)
    }

    try {
      final reportsNotifier =
          ref.read(agentReportsProvider(user.id).notifier);
      final report = await reportsNotifier.submitReport(
        agentId: user.id,
        agentName: user.name,
        imagePath: captureState.image!.path,
        latitude: captureState.latitude ?? 8.5241,
        longitude: captureState.longitude ?? 76.9366,
        locationName: captureState.locationName,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );

      if (!mounted) return;

      if (report != null) {
        // Process with AI model in background
        _runModelProcessing(report.id, captureState);

        // Navigate to processing result screen
        context.pushReplacement(
            '${AppRoutes.processingResult}?reportId=${report.id}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _runModelProcessing(String reportId, CaptureState captureState) {
    final modelService = ref.read(modelProcessingServiceProvider);
    final dataService = ref.read(dataAcquisitionServiceProvider);

    modelService
        .analyzeImage(
      reportId: reportId,
      imagePath: captureState.image!.path,
      latitude: captureState.latitude ?? 8.5241,
      longitude: captureState.longitude ?? 76.9366,
    )
        .then((result) async {
      await dataService.updateReportWithProcessingResult(
        reportId: reportId,
        result: result,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(captureStateProvider);

    if (captureState.image == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Preview')),
        body: const Center(child: Text('No image captured')),
      );
    }

    final dateStr = DateFormat('dd/MM/yyyy').format(captureState.capturedAt);
    final timeStr = DateFormat('HH:mm').format(captureState.capturedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
        backgroundColor: AppColors.agentColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        buildFileImage(
                          path: captureState.image!.path,
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                        // Top-right badge: Captured
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_outlined,
                                    color: AppColors.accent, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Captured',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom-left badge: Validated
                        if (captureState.validationResult != null)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A7A4A).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_outlined,
                                      color: Colors.white, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sea validated · ${(captureState.validationResult!.confidence * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Report details card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sea Condition Report',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Data will be analyzed by AI model upon submission',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          const Divider(height: 20),
                          if (captureState.isLoadingLocation) ...[
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Getting GPS location...'),
                              ],
                            ),
                          ] else ...[
                            InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'LATITUDE',
                              value: captureState.latitude != null
                                  ? captureState.latitude!.toStringAsFixed(6)
                                  : 'Unavailable',
                            ),
                            InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'LONGITUDE',
                              value: captureState.longitude != null
                                  ? captureState.longitude!.toStringAsFixed(6)
                                  : 'Unavailable',
                            ),
                            if (captureState.locationName != null)
                              InfoRow(
                                icon: Icons.place_outlined,
                                label: 'LOCATION',
                                value: captureState.locationName!,
                              ),
                          ],
                          InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'DATE',
                            value: dateStr,
                          ),
                          InfoRow(
                            icon: Icons.access_time_outlined,
                            label: 'TIME',
                            value: timeStr,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description field
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Optional Description',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Describe what you observed... (wave patterns, sea color, unusual conditions)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // AI notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI Model Processing will begin immediately after submission',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.agentColor,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload_outlined),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Report',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
