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
import '../../models/hazard_model.dart';
import '../../models/report_model.dart';

class IncidentDetailScreen extends ConsumerStatefulWidget {
  final String hazardId;
  const IncidentDetailScreen({super.key, required this.hazardId});

  @override
  ConsumerState<IncidentDetailScreen> createState() =>
      _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  HazardModel? _hazard;
  ReportModel? _report;
  MitigationActionModel? _mitigation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hazardService = ref.read(hazardMonitoringServiceProvider);
    final allHazards = await hazardService.getAllHazards();
    if (allHazards.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    HazardModel hazard;
    try {
      hazard = allHazards.firstWhere((h) => h.id == widget.hazardId);
    } catch (_) {
      hazard = allHazards.first;
    }

    final reportService = ref.read(reportManagementServiceProvider);
    final report = await reportService.getReportById(hazard.reportId);

    final mitigationService = ref.read(mitigationServiceProvider);
    final mitigation =
        await mitigationService.getActionByHazardId(hazard.id);

    if (mounted) {
      setState(() {
        _hazard = hazard;
        _report = report;
        _mitigation = mitigation;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final hazard = _hazard;
    if (hazard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(child: Text('Incident not found')),
      );
    }

    final severityColor = _getSeverityColor(hazard.severity);

    return Scaffold(
      appBar: AppBar(
        title: Text(hazard.displayId),
        backgroundColor: AppColors.primaryDeep,
        actions: [
          if (_mitigation == null)
            TextButton(
              onPressed: () => context
                  .push('${AppRoutes.createMitigation}?hazardId=${hazard.id}')
                  .then((_) => _loadData()),
              child: const Text(
                'Mitigate',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: severityColor.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: severityColor,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hazard.hazardType,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SeverityBadge(severity: hazard.severity),
                            const SizedBox(width: 8),
                            StatusChip(status: hazard.incidentStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location & detection info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Incident Information'),
                    InfoRow(
                      icon: Icons.place_outlined,
                      label: 'LOCATION',
                      value: hazard.locationName ??
                          '${hazard.latitude.toStringAsFixed(4)}, ${hazard.longitude.toStringAsFixed(4)}',
                    ),
                    InfoRow(
                      icon: Icons.my_location,
                      label: 'GPS COORDINATES',
                      value:
                          '${hazard.latitude.toStringAsFixed(6)}, ${hazard.longitude.toStringAsFixed(6)}',
                    ),
                    InfoRow(
                      icon: Icons.access_time_outlined,
                      label: 'DETECTED AT',
                      value: DateFormat('dd MMM yyyy, HH:mm')
                          .format(hazard.detectedAt),
                    ),
                    const Divider(),
                    ConfidenceMeter(confidence: hazard.confidenceScore),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Verification: ',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        VerificationChip(
                            status: hazard.verificationStatus, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Report info
            if (_report != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Original Report'),
                      _buildImagePreview(_report!),
                      const SizedBox(height: 12),
                      InfoRow(
                        icon: Icons.person_outline,
                        label: 'REPORTED BY',
                        value: _report!.agentName,
                      ),
                      InfoRow(
                        icon: Icons.description_outlined,
                        label: 'REPORT ID',
                        value: _report!.displayId,
                      ),
                      if (_report!.description != null)
                        InfoRow(
                          icon: Icons.notes,
                          label: 'DESCRIPTION',
                          value: _report!.description!,
                        ),
                      if (_report!.processingResult != null) ...[
                        const Divider(),
                        const SizedBox(height: 4),
                        Text(
                          _report!.processingResult!.observation,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => context.push(
                            '${AppRoutes.reportDetail}?id=${_report!.id}'),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View Full Report'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Verification summary
            if (_report != null &&
                _report!.verifications.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Verification Results'),
                      ..._report!.verifications.map(
                        (v) => _VerificationEntry(entry: v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Mitigation status
            if (_mitigation != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MITIGATION ACTION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              letterSpacing: 1,
                            ),
                          ),
                          StatusChip(status: _mitigation!.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _mitigation!.displayId,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      InfoRow(
                        icon: Icons.engineering_outlined,
                        label: 'ASSIGNED TEAM',
                        value: _mitigation!.assignedTeam,
                      ),
                      InfoRow(
                        icon: Icons.task_outlined,
                        label: 'ACTION TAKEN',
                        value: _mitigation!.actionTaken,
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.push(AppRoutes.mitigation),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View Mitigation'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            if (_mitigation == null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context
                      .push(
                          '${AppRoutes.createMitigation}?hazardId=${hazard.id}')
                      .then((_) => _loadData()),
                  icon: const Icon(Icons.engineering_outlined),
                  label: const Text('Create Mitigation Action'),
                ),
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.hazardMap),
                icon: const Icon(Icons.map_outlined),
                label: const Text('View on Map'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ReportModel report) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: report.imagePath.startsWith('assets/')
          ? Container(
              width: double.infinity,
              height: 160,
              color: AppColors.primaryMid,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.waves, size: 48, color: Colors.white54),
                    SizedBox(height: 6),
                    Text('Sea Photograph',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            )
          : buildFileImage(
              path: report.imagePath,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: AppColors.primaryMid,
                child: const Center(
                  child: Icon(Icons.waves, size: 48, color: Colors.white54),
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

class _VerificationEntry extends StatelessWidget {
  final VerificationEntryModel entry;
  const _VerificationEntry({required this.entry});

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
          Icon(Icons.verified_outlined, color: _color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.verifierName} (${UserRole.displayName(entry.verifierRole)})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (entry.comment != null)
                  Text(
                    '"${entry.comment}"',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
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
