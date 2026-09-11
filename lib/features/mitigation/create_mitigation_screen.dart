import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/hazard_model.dart';

class CreateMitigationScreen extends ConsumerStatefulWidget {
  final String hazardId;
  const CreateMitigationScreen({super.key, required this.hazardId});

  @override
  ConsumerState<CreateMitigationScreen> createState() =>
      _CreateMitigationScreenState();
}

class _CreateMitigationScreenState
    extends ConsumerState<CreateMitigationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actionController = TextEditingController();
  final _teamController = TextEditingController(
    text: 'Emergency Response Team Alpha',
  );
  final _safetyController = TextEditingController();
  bool _isSubmitting = false;
  HazardModel? _hazard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHazard();
  }

  Future<void> _loadHazard() async {
    final service = ref.read(hazardMonitoringServiceProvider);
    final all = await service.getAllHazards();
    if (all.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    HazardModel hazard;
    try {
      hazard = all.firstWhere((h) => h.id == widget.hazardId);
    } catch (_) {
      hazard = all.first;
    }
    if (mounted) {
      setState(() {
        _hazard = hazard;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _actionController.dispose();
    _teamController.dispose();
    _safetyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hazard == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(mitigationServiceProvider);
      await service.createAction(
        hazardId: _hazard!.id,
        reportId: _hazard!.reportId,
        hazardType: _hazard!.hazardType,
        severity: _hazard!.severity,
        actionTaken: _actionController.text.trim(),
        assignedTeam: _teamController.text.trim(),
        safetyInstructions: _safetyController.text.trim(),
        officerId: user.id,
        officerName: user.name,
      );

      ref.invalidate(mitigationActionsProvider);
      ref.invalidate(allHazardsProvider);
      ref.invalidate(activeHazardsProvider);
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mitigation action created successfully'),
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hazard = _hazard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Mitigation Action'),
        backgroundColor: AppColors.primaryDeep,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hazard summary
                    if (hazard != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.alertBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.alertBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.alertBorder,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hazard.hazardType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                SeverityBadge(severity: hazard.severity),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hazard.locationName ??
                                  '${hazard.latitude.toStringAsFixed(4)}, ${hazard.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SectionHeader(title: 'Mitigation Details'),

                    // Action taken
                    TextFormField(
                      controller: _actionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Action Taken *',
                        hintText:
                            'Describe the action being taken (e.g., Coastal inspection initiated, barricades placed...)',
                        prefixIcon: Icon(Icons.task_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please describe the action'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Assigned team
                    TextFormField(
                      controller: _teamController,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Team *',
                        prefixIcon: Icon(Icons.group_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter the assigned team'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Safety instructions
                    TextFormField(
                      controller: _safetyController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Safety Instructions *',
                        hintText:
                            'Safety measures for the public and response team...',
                        prefixIcon: Icon(Icons.health_and_safety_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please provide safety instructions'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Status info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusInProgress.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.statusInProgress.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.statusInProgress,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Status will be set to IN PROGRESS upon creation',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.statusInProgress,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status timeline preview
                    const Text(
                      'STATUS WORKFLOW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StatusTimeline(),
                    const SizedBox(height: 16),
                  ],
                ),
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
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting ? 'Creating...' : 'Create Mitigation Action',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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

class _StatusTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'PENDING', 'color': AppColors.statusPending},
      {'label': 'IN PROGRESS', 'color': AppColors.statusInProgress},
      {'label': 'MITIGATED', 'color': AppColors.statusMitigated},
      {'label': 'RESOLVED', 'color': AppColors.statusResolved},
    ];

    return Row(
      children: steps.asMap().entries.map((e) {
        final isLast = e.key == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (e.value['color'] as Color).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: e.value['color'] as Color,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            color: e.value['color'] as Color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.value['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: e.value['color'] as Color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(height: 2, width: 16, color: AppColors.border),
            ],
          ),
        );
      }).toList(),
    );
  }
}
