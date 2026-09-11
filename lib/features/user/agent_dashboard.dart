import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/report_model.dart';

class AgentDashboard extends ConsumerStatefulWidget {
  const AgentDashboard({super.key});

  @override
  ConsumerState<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends ConsumerState<AgentDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final reportsAsync = ref.watch(agentReportsProvider(user?.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.agentColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.agentColor,
                      AppColors.agentColor.withOpacity(0.7),
                      const Color(0xFF004D40),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.waves,
                                    color: Colors.white70, size: 20),
                                const SizedBox(width: 6),
                                const Text(
                                  'WavesLive',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.profile),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'Agent'} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Local Agent — Data Acquisition',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main action — Capture
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.dataAcquisition),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.agentColor,
                            AppColors.agentColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.agentColor.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Capture Sea Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Open camera to capture sea condition photograph with GPS',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Open Camera',
                                    style: TextStyle(
                                      color: AppColors.agentColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  reportsAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (reports) {
                      final total = reports.length;
                      final hazards =
                          reports.where((r) => r.hasHazard).length;
                      final verified = reports
                          .where((r) =>
                              r.verificationStatus ==
                              VerificationStatus.verified)
                          .length;
                      return Row(
                        children: [
                          Expanded(
                            child: _StatMini(
                              label: 'Total Reports',
                              value: '$total',
                              icon: Icons.description_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatMini(
                              label: 'Hazards Found',
                              value: '$hazards',
                              icon: Icons.warning_amber_outlined,
                              color: AppColors.severityHigh,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatMini(
                              label: 'Verified',
                              value: '$verified',
                              icon: Icons.verified_outlined,
                              color: AppColors.statusResolved,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Recent Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.myReports),
                        child: const Text('View All'),
                      ),
                    ],
                  ),

                  reportsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (reports) {
                      if (reports.isEmpty) {
                        return EmptyState(
                          icon: Icons.camera_alt_outlined,
                          title: 'No Reports Yet',
                          subtitle: 'Capture your first sea condition photograph',
                          action: ElevatedButton(
                            onPressed: () =>
                                context.push(AppRoutes.dataAcquisition),
                            child: const Text('Capture Now'),
                          ),
                        );
                      }
                      return Column(
                        children: reports
                            .take(5)
                            .map((r) => _ReportTile(report: r))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.dataAcquisition),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capture'),
        backgroundColor: AppColors.agentColor,
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatMini({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primaryDeep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final ReportModel report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
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
            size: 22,
          ),
        ),
        title: Text(
          report.displayId,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.processingResult?.hazardType ??
                  (report.processingStatus == ProcessingStatus.processing
                      ? 'Processing...'
                      : 'No hazard'),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (report.processingResult != null)
                  SeverityBadge(
                      severity: report.processingResult!.severity,
                      compact: true),
                const SizedBox(width: 6),
                VerificationChip(
                    status: report.verificationStatus, compact: true),
              ],
            ),
          ],
        ),
        trailing: Text(
          _timeAgo(report.submittedAt),
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
        onTap: () =>
            context.push('${AppRoutes.reportDetail}?id=${report.id}'),
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
