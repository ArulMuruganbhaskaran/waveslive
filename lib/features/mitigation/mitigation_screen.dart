import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/hazard_model.dart';

class MitigationScreen extends ConsumerWidget {
  const MitigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(mitigationActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mitigation Actions'),
        backgroundColor: AppColors.primaryDeep,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mitigationActionsProvider),
          ),
        ],
      ),
      body: actionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (actions) {
          if (actions.isEmpty) {
            return const EmptyState(
              icon: Icons.engineering_outlined,
              title: 'No Mitigation Actions',
              subtitle:
                  'Create mitigation actions from incident details when hazards are confirmed',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            itemBuilder: (context, idx) =>
                _MitigationCard(action: actions[idx]),
          );
        },
      ),
    );
  }
}

class _MitigationCard extends ConsumerWidget {
  final MitigationActionModel action;
  const _MitigationCard({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.displayId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        action.hazardType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: action.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.engineering_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    action.assignedTeam,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Officer: ${action.officerName}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                SeverityBadge(severity: action.severity, compact: true),
              ],
            ),
            const SizedBox(height: 10),

            // Status update buttons (for in-progress)
            if (action.status == IncidentStatus.inProgress ||
                action.status == IncidentStatus.pending) ...[
              const Divider(),
              Row(
                children: [
                  if (action.status == IncidentStatus.inProgress)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus(
                          context,
                          ref,
                          action,
                          IncidentStatus.mitigated,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusMitigated,
                          side: const BorderSide(
                              color: AppColors.statusMitigated),
                        ),
                        child: const Text('Mark Mitigated'),
                      ),
                    ),
                  if (action.status == IncidentStatus.inProgress)
                    const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(
                        context,
                        ref,
                        action,
                        IncidentStatus.resolved,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusResolved,
                      ),
                      child: const Text('Mark Resolved'),
                    ),
                  ),
                ],
              ),
            ],

            if (action.status == IncidentStatus.mitigated) ...[
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(
                    context,
                    ref,
                    action,
                    IncidentStatus.resolved,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusResolved,
                  ),
                  child: const Text('Mark Resolved'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    MitigationActionModel action,
    String newStatus,
  ) async {
    final user = ref.read(currentUserProvider);
    final service = ref.read(mitigationServiceProvider);

    final note = newStatus == IncidentStatus.mitigated
        ? 'Hazard mitigated. Safety measures applied.'
        : 'Incident fully resolved. Normal operations resumed.';

    await service.updateStatus(
      actionId: action.id,
      newStatus: newStatus,
      note: note,
      officerId: user?.id ?? '',
    );

    ref.invalidate(mitigationActionsProvider);
    ref.invalidate(allHazardsProvider);
    ref.invalidate(activeHazardsProvider);
    ref.invalidate(dashboardStatsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${IncidentStatus.displayName(newStatus)}'),
          backgroundColor: AppColors.statusResolved,
        ),
      );
    }
  }
}
