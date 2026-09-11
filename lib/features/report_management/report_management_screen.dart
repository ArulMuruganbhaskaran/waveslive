import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/report_model.dart';

class ReportManagementScreen extends ConsumerStatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  ConsumerState<ReportManagementScreen> createState() =>
      _ReportManagementScreenState();
}

class _ReportManagementScreenState
    extends ConsumerState<ReportManagementScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(reportFilterProvider);
    final reportsAsync = ref.watch(filteredReportsProvider);
    final hasFilters = filters.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Management'),
        backgroundColor: AppColors.primaryDeep,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(_showFilters
                    ? Icons.filter_list_off
                    : Icons.filter_list),
                onPressed: () =>
                    setState(() => _showFilters = !_showFilters),
              ),
              if (hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by location, hazard type, ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(reportFilterProvider.notifier)
                              .clearFilter('search');
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                if (v.isEmpty) {
                  ref
                      .read(reportFilterProvider.notifier)
                      .clearFilter('search');
                } else {
                  ref
                      .read(reportFilterProvider.notifier)
                      .setFilter('search', v);
                }
              },
            ),
          ),

          // Filter panel
          if (_showFilters)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FILTERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.textHint,
                        ),
                      ),
                      if (hasFilters)
                        TextButton(
                          onPressed: () => ref
                              .read(reportFilterProvider.notifier)
                              .clearAll(),
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    label: 'Severity',
                    options: const ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
                    selected: filters['severity'],
                    onSelect: (v) => ref
                        .read(reportFilterProvider.notifier)
                        .setFilter('severity', v),
                    onClear: () => ref
                        .read(reportFilterProvider.notifier)
                        .clearFilter('severity'),
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    label: 'Verification',
                    options: const [
                      'PENDING',
                      'VERIFIED',
                      'SUSPICIOUS',
                      'REJECTED'
                    ],
                    selected: filters['verificationStatus'],
                    onSelect: (v) => ref
                        .read(reportFilterProvider.notifier)
                        .setFilter('verificationStatus', v),
                    onClear: () => ref
                        .read(reportFilterProvider.notifier)
                        .clearFilter('verificationStatus'),
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    label: 'Status',
                    options: const [
                      'PENDING',
                      'IN_PROGRESS',
                      'MITIGATED',
                      'RESOLVED'
                    ],
                    displayNames: const [
                      'Pending',
                      'In Progress',
                      'Mitigated',
                      'Resolved'
                    ],
                    selected: filters['incidentStatus'],
                    onSelect: (v) => ref
                        .read(reportFilterProvider.notifier)
                        .setFilter('incidentStatus', v),
                    onClear: () => ref
                        .read(reportFilterProvider.notifier)
                        .clearFilter('incidentStatus'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Results
          Expanded(
            child: reportsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reports) {
                if (reports.isEmpty) {
                  return EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No Reports Found',
                    subtitle: hasFilters
                        ? 'Try adjusting your filters'
                        : 'No reports have been submitted yet',
                    action: hasFilters
                        ? TextButton(
                            onPressed: () => ref
                                .read(reportFilterProvider.notifier)
                                .clearAll(),
                            child: const Text('Clear Filters'),
                          )
                        : null,
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${reports.length} report${reports.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: reports.length,
                        itemBuilder: (context, idx) =>
                            _ReportRow(report: reports[idx]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String>? displayNames;
  final String? selected;
  final Function(String) onSelect;
  final VoidCallback onClear;

  const _FilterRow({
    required this.label,
    required this.options,
    required this.onSelect,
    required this.onClear,
    this.selected,
    this.displayNames,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: options.asMap().entries.map((e) {
            final isSelected = selected == e.value;
            final displayName =
                displayNames != null ? displayNames![e.key] : e.value;
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  onClear();
                } else {
                  onSelect(e.value);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDeep
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDeep
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final ReportModel report;
  const _ReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () =>
            context.push('${AppRoutes.reportDetail}?id=${report.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: report.hasHazard
                      ? AppColors.severityHigh.withOpacity(0.1)
                      : AppColors.statusResolved.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  report.hasHazard
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: report.hasHazard
                      ? AppColors.severityHigh
                      : AppColors.statusResolved,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.displayId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(report.submittedAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                    Text(
                      report.processingResult?.hazardType ??
                          (report.processingStatus ==
                                  ProcessingStatus.processing
                              ? 'Processing...'
                              : 'No hazard'),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.locationName ??
                          '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (report.processingResult != null)
                          SeverityBadge(
                              severity: report.processingResult!.severity,
                              compact: true),
                        const SizedBox(width: 6),
                        VerificationChip(
                            status: report.verificationStatus,
                            compact: true),
                        const SizedBox(width: 6),
                        StatusChip(
                            status: report.incidentStatus, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
