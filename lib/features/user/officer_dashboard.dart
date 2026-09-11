import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/hazard_model.dart';
import '../../models/report_model.dart';

class OfficerDashboard extends ConsumerStatefulWidget {
  const OfficerDashboard({super.key});

  @override
  ConsumerState<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends ConsumerState<OfficerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _OfficerHome(),
    HazardMapPlaceholder(),
    AlertsPlaceholder(),
    ReportMgmtPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) {
          if (idx == 1) {
            context.push(AppRoutes.hazardMap);
            return;
          }
          if (idx == 2) {
            context.push(AppRoutes.alerts);
            return;
          }
          if (idx == 3) {
            context.push(AppRoutes.reportManagement);
            return;
          }
          setState(() => _selectedIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class _OfficerHome extends ConsumerWidget {
  const _OfficerHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activeHazardsAsync = ref.watch(activeHazardsProvider);
    final unreadAsync = user != null
        ? ref.watch(unreadAlertCountProvider(user.id))
        : const AsyncValue<int>.data(0);

    final stats = statsAsync.valueOrNull ?? {};
    final unreadAlerts = unreadAsync.valueOrNull ?? 0;

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, ref, user, unreadAlerts),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.35,
                  children: [
                    StatCard(
                      label: 'Active Hazards',
                      value: '${stats['active'] ?? 0}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.severityHigh,
                      onTap: () => context.push(AppRoutes.hazardMap),
                    ),
                    StatCard(
                      label: 'High Risk',
                      value: '${stats['highRisk'] ?? 0}',
                      icon: Icons.dangerous_outlined,
                      color: AppColors.severityCritical,
                      onTap: () => context.push(AppRoutes.hazardMap),
                    ),
                    StatCard(
                      label: 'Pending Verify',
                      value: '${stats['pendingVerification'] ?? 0}',
                      icon: Icons.pending_outlined,
                      color: AppColors.statusInProgress,
                    ),
                    StatCard(
                      label: 'Resolved',
                      value: '${stats['resolved'] ?? 0}',
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusResolved,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Unread alerts banner
                if (unreadAlerts > 0) ...[
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.alerts),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.alertBackground,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.alertBorder, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.alertBorder,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have $unreadAlerts unread alert${unreadAlerts > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.alertBorder,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.alertBorder,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Active hazards list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Hazards',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.hazardMap),
                      child: const Text('View Map'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                activeHazardsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (hazards) {
                    if (hazards.isEmpty) {
                      return const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'No Active Hazards',
                        subtitle: 'All clear! No hazards currently active.',
                      );
                    }
                    return Column(
                      children: hazards
                          .take(5)
                          .map((h) => _HazardListTile(hazard: h))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── AI Model Processing Results ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Processing Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.reportManagement),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Reports analysed by the AI model',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 12),

                ref.watch(aiProcessedReportsProvider).when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (reports) {
                    if (reports.isEmpty) {
                      return const EmptyState(
                        icon: Icons.auto_awesome_outlined,
                        title: 'No Results Yet',
                        subtitle: 'AI processing results will appear here.',
                      );
                    }
                    return Column(
                      children: reports
                          .take(5)
                          .map((r) => _AiResultTile(report: r))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Quick actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.map_outlined,
                        label: 'Live Map',
                        color: AppColors.primaryMid,
                        onTap: () => context.push(AppRoutes.hazardMap),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.engineering_outlined,
                        label: 'Mitigation',
                        color: AppColors.statusMitigated,
                        onTap: () => context.push(AppRoutes.mitigation),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.folder_open_outlined,
                        label: 'Reports',
                        color: AppColors.volunteerColor,
                        onTap: () => context.push(AppRoutes.reportManagement),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, WidgetRef ref, user, int unreadAlerts) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: AppColors.primaryDeep,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.oceanGradient,
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
                          const Icon(Icons.waves, color: AppColors.accent, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'WavesLive',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined,
                                    color: Colors.white),
                                onPressed: () =>
                                    context.push(AppRoutes.alerts),
                              ),
                              if (unreadAlerts > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.severityHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$unreadAlerts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.profile),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  Colors.white.withOpacity(0.15),
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'O',
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Good morning, ${user?.name.split(' ').first ?? 'Officer'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Coastal Officer Dashboard',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HazardListTile extends StatelessWidget {
  final HazardModel hazard;

  const _HazardListTile({required this.hazard});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _severityColor(hazard.severity).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: _severityColor(hazard.severity),
            size: 22,
          ),
        ),
        title: Text(
          hazard.hazardType,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              hazard.locationName ?? '${hazard.latitude.toStringAsFixed(4)}, ${hazard.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SeverityBadge(severity: hazard.severity, compact: true),
                const SizedBox(width: 8),
                StatusChip(status: hazard.incidentStatus, compact: true),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () => context.push(
            '${AppRoutes.incidentDetail}?id=${hazard.id}'),
      ),
    );
  }

  Color _severityColor(String severity) {
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

class _AiResultTile extends StatelessWidget {
  final ReportModel report;
  const _AiResultTile({required this.report});

  Color _severityColor(String severity) {
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

  @override
  Widget build(BuildContext context) {
    final result = report.processingResult!;
    final sColor = _severityColor(result.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: sColor.withValues(alpha: 0.25), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('${AppRoutes.reportDetail}?id=${report.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      result.hazardDetected
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: sColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.hazardType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          report.displayId,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SeverityBadge(severity: result.severity, compact: true),
                      const SizedBox(height: 4),
                      Text(
                        '${result.confidencePercentage} confidence',
                        style: TextStyle(
                          fontSize: 11,
                          color: sColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.observation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.locationName ??
                          '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder navigators (these push to dedicated screens)
class HazardMapPlaceholder extends StatelessWidget {
  const HazardMapPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class AlertsPlaceholder extends StatelessWidget {
  const AlertsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class ReportMgmtPlaceholder extends StatelessWidget {
  const ReportMgmtPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
