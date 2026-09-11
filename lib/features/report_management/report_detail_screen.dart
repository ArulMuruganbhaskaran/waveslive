import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/image_file_helper.dart';
import '../../models/report_model.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  ReportModel? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final service = ref.read(reportManagementServiceProvider);
    final report = await service.getReportById(widget.reportId);
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final report = _report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: const Center(child: Text('Report not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(report.displayId),
        backgroundColor: AppColors.primaryDeep,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      VerificationChip(status: report.verificationStatus),
                      const SizedBox(width: 8),
                      StatusChip(status: report.incidentStatus),
                    ],
                  ),
                ),
                if (report.processingResult != null)
                  SeverityBadge(severity: report.processingResult!.severity),
              ],
            ),

            const SizedBox(height: 16),

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
                    const SectionHeader(title: 'Report Information'),
                    InfoRow(
                      icon: Icons.description_outlined,
                      label: 'REPORT ID',
                      value: report.displayId,
                    ),
                    InfoRow(
                      icon: Icons.person_outline,
                      label: 'REPORTED BY',
                      value: report.agentName,
                    ),
                    InfoRow(
                      icon: Icons.place_outlined,
                      label: 'LOCATION',
                      value: report.locationName ?? 'No location name',
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
                      value: DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(report.capturedAt),
                    ),
                    InfoRow(
                      icon: Icons.upload_outlined,
                      label: 'SUBMITTED',
                      value: DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(report.submittedAt),
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

            // Model result
            if (report.processingResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'AI Model Processing Result'),
                      _buildModelResult(report.processingResult!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (report.processingStatus ==
                ProcessingStatus.processing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      const Text('AI Model Processing in progress...'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Verification results
            if (report.verifications.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Verification Results'),
                      _buildVerificationSummary(report),
                      const SizedBox(height: 12),
                      ...report.verifications.map((v) => _VerifEntry(entry: v)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons based on role
            _buildActionButtons(context, report),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ReportModel report) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: report.imagePath.startsWith('assets/')
          ? Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryMid, AppColors.primaryDeep],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.waves, size: 64, color: Colors.white38),
                    SizedBox(height: 10),
                    Text(
                      'Sea Condition Photograph',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : buildFileImage(
              path: report.imagePath,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: AppColors.primaryMid,
                child: const Center(
                  child: Icon(Icons.waves, size: 64, color: Colors.white38),
                ),
              ),
            ),
    );
  }

  Widget _buildModelResult(ProcessingResultModel result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                result.hazardType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SeverityBadge(severity: result.severity),
          ],
        ),
        const SizedBox(height: 10),
        ConfidenceMeter(confidence: result.confidenceScore),
        const SizedBox(height: 12),
        const Text(
          'OBSERVATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          result.observation,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 10),
        const Text(
          'RECOMMENDATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.alertBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            result.recommendation,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.alertBorder,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSummary(ReportModel report) {
    final vs = report.verifications;
    final genuineCount =
        vs.where((v) => v.result == VerificationResult.genuine).length;
    final suspiciousCount =
        vs.where((v) => v.result == VerificationResult.suspicious).length;
    final falseCount =
        vs.where((v) => v.result == VerificationResult.falsified).length;
    String overallStatus;
    if (vs.isEmpty) {
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _VerifCount(
            label: 'Genuine',
            count: summary.genuineCount,
            color: AppColors.genuine,
          ),
          _VerifCount(
            label: 'Suspicious',
            count: summary.suspiciousCount,
            color: AppColors.suspicious,
          ),
          _VerifCount(
            label: 'False',
            count: summary.falseCount,
            color: AppColors.falsified,
          ),
          Column(
            children: [
              const Text(
                'Overall',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              const SizedBox(height: 4),
              VerificationChip(status: summary.overallStatus, compact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ReportModel report) {
    final user = ref.read(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user.role == UserRole.officer &&
            report.processingResult?.hazardDetected == true) ...[
          ElevatedButton.icon(
            onPressed: () async {
              final hazardService = ref.read(hazardMonitoringServiceProvider);
              final hazard = await hazardService.getHazardByReportId(report.id);
              if (hazard != null && context.mounted) {
                context.push('${AppRoutes.incidentDetail}?id=${hazard.id}');
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('View Incident'),
          ),
          const SizedBox(height: 8),
        ],
        if ((user.role == UserRole.volunteer || user.role == UserRole.ngo) &&
            report.verificationStatus == VerificationStatus.pending &&
            report.processingResult?.hazardDetected == true) ...[
          ElevatedButton.icon(
            onPressed: () => context.push(
              '${AppRoutes.verificationDetail}?reportId=${report.id}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.volunteerColor,
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Verify This Report'),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _VerifCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VerifCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _VerifEntry extends StatelessWidget {
  final VerificationEntryModel entry;
  const _VerifEntry({required this.entry});

  Color get _color {
    switch (entry.result) {
      case VerificationResult.genuine:
        return AppColors.genuine;
      case VerificationResult.suspicious:
        return AppColors.suspicious;
      case VerificationResult.falsified:
        return AppColors.falsified;
      default:
        return AppColors.textHint;
    }
  }

  String get _label {
    switch (entry.result) {
      case VerificationResult.genuine:
        return 'Genuine';
      case VerificationResult.suspicious:
        return 'Suspicious';
      case VerificationResult.falsified:
        return 'False';
      default:
        return entry.result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _color.withOpacity(0.15),
            child: Text(
              entry.verifierName[0].toUpperCase(),
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.verifierName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  UserRole.displayName(entry.verifierRole),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                if (entry.comment != null)
                  Text(
                    '"${entry.comment}"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _label,
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
