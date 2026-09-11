import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/hazard_model.dart';

class AlertDetailScreen extends ConsumerStatefulWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  AlertModel? _alert;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlert();
  }

  Future<void> _loadAlert() async {
    final user = ref.read(currentUserProvider);
    final service = ref.read(alertServiceProvider);
    final alerts = await service.getAlertsForOfficer(user?.id ?? '');
    if (alerts.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    AlertModel alert;
    try {
      alert = alerts.firstWhere((a) => a.id == widget.alertId);
    } catch (_) {
      alert = alerts.first;
    }
    await service.markAlertRead(alert.id);
    if (mounted) {
      setState(() {
        _alert = alert;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final alert = _alert;
    if (alert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alert')),
        body: const Center(child: Text('Alert not found')),
      );
    }

    final levelColor = _levelColor(alert.level);

    return Scaffold(
      appBar: AppBar(
        title: Text(alert.displayId),
        backgroundColor: levelColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: levelColor.withOpacity(0.4), width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    alert.level == AlertLevel.critical
                        ? Icons.dangerous
                        : Icons.warning_amber_rounded,
                    color: levelColor,
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '⚠ ${alert.level} COASTAL ALERT',
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.hazardType,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SeverityBadge(severity: alert.severity),
                      const SizedBox(width: 8),
                      VerificationChip(status: alert.verificationStatus),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Alert Details'),
                    InfoRow(
                      icon: Icons.place_outlined,
                      label: 'LOCATION',
                      value: alert.locationName ??
                          '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
                    ),
                    InfoRow(
                      icon: Icons.my_location,
                      label: 'GPS',
                      value:
                          '${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}',
                    ),
                    InfoRow(
                      icon: Icons.access_time_outlined,
                      label: 'ISSUED AT',
                      value: DateFormat('dd MMM yyyy, HH:mm')
                          .format(alert.createdAt),
                    ),
                    const Divider(),
                    ConfidenceMeter(confidence: alert.confidenceScore),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Recommended Action'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: levelColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.task_alt_outlined,
                              color: levelColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              alert.recommendedAction,
                              style: TextStyle(
                                fontSize: 14,
                                color: levelColor,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(
                    '${AppRoutes.incidentDetail}?id=${alert.hazardId}'),
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Incident Details'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                    '${AppRoutes.createMitigation}?hazardId=${alert.hazardId}'),
                icon: const Icon(Icons.engineering_outlined),
                label: const Text('Create Mitigation Action'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.hazardMap),
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

  Color _levelColor(String level) {
    switch (level) {
      case AlertLevel.critical:
        return AppColors.severityCritical;
      case AlertLevel.high:
        return AppColors.severityHigh;
      case AlertLevel.warning:
        return AppColors.severityMedium;
      default:
        return AppColors.statusInProgress;
    }
  }
}
