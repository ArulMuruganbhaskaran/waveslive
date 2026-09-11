import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/report_model.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final reportsAsync = ref.watch(agentReportsProvider(user?.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: AppColors.agentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => context.push(AppRoutes.dataAcquisition),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) {
          if (reports.isEmpty) {
            return EmptyState(
              icon: Icons.description_outlined,
              title: 'No Reports',
              subtitle: 'Capture your first sea condition photograph',
              action: ElevatedButton(
                onPressed: () => context.push(AppRoutes.dataAcquisition),
                child: const Text('Capture Now'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, idx) => _ReportCard(report: reports[idx]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.dataAcquisition),
        backgroundColor: AppColors.agentColor,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm').format(report.submittedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () =>
            context.push('${AppRoutes.reportDetail}?id=${report.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.displayId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusChip(status: report.incidentStatus, compact: true),
                ],
              ),
              if (report.processingResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  report.processingResult!.hazardType,
                  style: TextStyle(
                    fontSize: 13,
                    color: report.hasHazard
                        ? AppColors.severityHigh
                        : AppColors.statusResolved,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (report.processingStatus ==
                  ProcessingStatus.processing) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('AI Analysis in progress...',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.locationName ??
                          '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (report.processingResult != null)
                    SeverityBadge(
                        severity: report.processingResult!.severity,
                        compact: true),
                  const SizedBox(width: 8),
                  VerificationChip(
                      status: report.verificationStatus, compact: true),
                  const Spacer(),
                  if (report.processingResult != null)
                    Text(
                      '${report.processingResult!.confidencePercentage} confidence',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
