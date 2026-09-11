import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/image_file_helper.dart';
import '../../models/report_model.dart';

class VerificationDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  const VerificationDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<VerificationDetailScreen> createState() =>
      _VerificationDetailScreenState();
}

class _VerificationDetailScreenState
    extends ConsumerState<VerificationDetailScreen> {
  String? _selectedResult;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  ReportModel? _report;
  bool _isLoading = true;
  bool _alreadyVerified = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final service = ref.read(verificationServiceProvider);
    await service.getPendingVerifications(); // preload queue
    // Also check all reports
    final allService = ref.read(reportManagementServiceProvider);
    final report = await allService.getReportById(widget.reportId);

    final user = ref.read(currentUserProvider);
    final alreadyVerified = report?.verifications
            .any((v) => v.verifierId == user?.id) ??
        false;

    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
        _alreadyVerified = alreadyVerified;
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_selectedResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a verification result')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(verificationServiceProvider);
      final entry = VerificationEntryModel(
        verifierId: user.id,
        verifierName: user.name,
        verifierRole: user.role,
        result: _selectedResult!,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        verifiedAt: DateTime.now(),
      );

      await service.submitVerification(
        reportId: widget.reportId,
        entry: entry,
      );

      // Invalidate providers
      ref.invalidate(pendingVerificationsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted successfully'),
            backgroundColor: AppColors.statusResolved,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final report = _report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verification')),
        body: const Center(child: Text('Report not found')),
      );
    }

    final result = report.processingResult!;
    // Compute verification summary inline (no longer a service method)
    final verifications = report.verifications;
    final genuineCount =
        verifications.where((v) => v.result == VerificationResult.genuine).length;
    final suspiciousCount =
        verifications.where((v) => v.result == VerificationResult.suspicious).length;
    final falseCount =
        verifications.where((v) => v.result == VerificationResult.falsified).length;
    String overallStatus;
    if (verifications.isEmpty) {
      overallStatus = VerificationStatus.pending;
    } else if (genuineCount > falseCount && genuineCount > suspiciousCount) {
      overallStatus = VerificationStatus.verified;
    } else if (falseCount >= genuineCount) {
      overallStatus = VerificationStatus.rejected;
    } else {
      overallStatus = VerificationStatus.suspicious;
    }
    final summary = VerificationSummaryModel(
      genuineCount: genuineCount,
      suspiciousCount: suspiciousCount,
      falseCount: falseCount,
      overallStatus: overallStatus,
    );


    return Scaffold(
      appBar: AppBar(
        title: Text(report.displayId),
        backgroundColor: AppColors.volunteerColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  _buildImageSection(report),

                  const SizedBox(height: 16),

                  // Report info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Report Details'),
                          InfoRow(
                            icon: Icons.person_outline,
                            label: 'AGENT',
                            value: report.agentName,
                          ),
                          InfoRow(
                            icon: Icons.place_outlined,
                            label: 'LOCATION',
                            value: report.locationName ??
                                '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                          ),
                          InfoRow(
                            icon: Icons.my_location,
                            label: 'GPS',
                            value:
                                '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                          ),
                          InfoRow(
                            icon: Icons.access_time_outlined,
                            label: 'CAPTURED',
                            value: DateFormat('dd MMM yyyy, HH:mm')
                                .format(report.capturedAt),
                          ),
                          if (report.description != null)
                            InfoRow(
                              icon: Icons.notes,
                              label: 'AGENT DESCRIPTION',
                              value: report.description!,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // AI Result
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Model Processing Result'),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(result.severity)
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      result.hazardType,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Spacer(),
                                    SeverityBadge(severity: result.severity),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ConfidenceMeter(
                                    confidence: result.confidenceScore),
                                const SizedBox(height: 10),
                                Text(
                                  result.observation,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Existing verifications summary
                  if (report.verifications.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Verification Summary'),
                            Row(
                              children: [
                                _VerifStat(
                                  label: 'Genuine',
                                  count: summary.genuineCount,
                                  color: AppColors.genuine,
                                ),
                                _VerifStat(
                                  label: 'Suspicious',
                                  count: summary.suspiciousCount,
                                  color: AppColors.suspicious,
                                ),
                                _VerifStat(
                                  label: 'False',
                                  count: summary.falseCount,
                                  color: AppColors.falsified,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text(
                                  'Overall Status: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                VerificationChip(status: summary.overallStatus),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Already verified notice
                  if (_alreadyVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.statusResolved.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.statusResolved.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppColors.statusResolved),
                          SizedBox(width: 10),
                          Text(
                            'You have already verified this report',
                            style: TextStyle(
                              color: AppColors.statusResolved,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Verification section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(title: 'Your Verification'),
                            const SizedBox(height: 4),
                            const Text(
                              'Based on the photograph and AI analysis, mark your verification:',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            _VerificationOption(
                              result: VerificationResult.genuine,
                              label: 'Genuine',
                              description:
                                  'The hazard appears real and genuine',
                              icon: Icons.check_circle_outline,
                              color: AppColors.genuine,
                              selected: _selectedResult ==
                                  VerificationResult.genuine,
                              onTap: () => setState(() =>
                                  _selectedResult =
                                      VerificationResult.genuine),
                            ),
                            _VerificationOption(
                              result: VerificationResult.suspicious,
                              label: 'Suspicious',
                              description:
                                  'The report needs further investigation',
                              icon: Icons.warning_amber_outlined,
                              color: AppColors.suspicious,
                              selected: _selectedResult ==
                                  VerificationResult.suspicious,
                              onTap: () => setState(() =>
                                  _selectedResult =
                                      VerificationResult.suspicious),
                            ),
                            _VerificationOption(
                              result: VerificationResult.falsified,
                              label: 'False',
                              description: 'The hazard appears to be false',
                              icon: Icons.cancel_outlined,
                              color: AppColors.falsified,
                              selected: _selectedResult ==
                                  VerificationResult.falsified,
                              onTap: () => setState(() =>
                                  _selectedResult =
                                      VerificationResult.falsified),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _commentController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment (optional)...',
                                prefixIcon: Icon(Icons.comment_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Submit button
          if (!_alreadyVerified)
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
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.volunteerColor,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text(
                            'Submit Verification',
                            style: TextStyle(
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

  Widget _buildImageSection(ReportModel report) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: report.imagePath.startsWith('assets/')
          ? Container(
              width: double.infinity,
              height: 200,
              color: AppColors.primaryMid,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.waves, size: 60, color: Colors.white54),
                  SizedBox(height: 8),
                  Text('Sea Photograph',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : buildFileImage(
              path: report.imagePath,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.primaryMid,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.waves, size: 60, color: Colors.white54),
                      SizedBox(height: 8),
                      Text('Sea Photograph',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case HazardSeverity.critical:
        return AppColors.severityCritical;
      case HazardSeverity.high:
        return AppColors.severityHigh;
      case HazardSeverity.medium:
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }
}

class _VerifStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VerifStat(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _VerificationOption extends StatelessWidget {
  final String result;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _VerificationOption({
    required this.result,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : AppColors.textHint, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: selected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? color.withOpacity(0.8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 20)
            else
              const Icon(Icons.radio_button_unchecked,
                  color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
