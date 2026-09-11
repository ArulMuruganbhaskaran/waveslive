import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/hazard_model.dart';

class HazardMapScreen extends ConsumerStatefulWidget {
  const HazardMapScreen({super.key});

  @override
  ConsumerState<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends ConsumerState<HazardMapScreen> {
  HazardModel? _selectedHazard;
  final MapController _mapController = MapController();
  String _filterSeverity = '';

  @override
  Widget build(BuildContext context) {
    final allHazardsAsync = ref.watch(allHazardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Hazard Map'),
        backgroundColor: AppColors.primaryDeep,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filterSeverity = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('All Hazards')),
              const PopupMenuItem(value: 'CRITICAL', child: Text('Critical')),
              const PopupMenuItem(value: 'HIGH', child: Text('High')),
              const PopupMenuItem(value: 'MEDIUM', child: Text('Medium')),
              const PopupMenuItem(value: 'LOW', child: Text('Low')),
            ],
          ),
        ],
      ),
      body: allHazardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (hazards) {
          final filtered = _filterSeverity.isEmpty
              ? hazards
              : hazards
                  .where((h) => h.severity == _filterSeverity)
                  .toList();

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: filtered.isNotEmpty
                      ? LatLng(filtered.first.latitude,
                          filtered.first.longitude)
                      : const LatLng(8.5241, 76.9366),
                  initialZoom: 10,
                  onTap: (_, __) => setState(() => _selectedHazard = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.waveslive.app',
                  ),
                  MarkerLayer(
                    markers: filtered.map((h) => _buildMarker(h)).toList(),
                  ),
                ],
              ),

              // Filter chip
              if (_filterSeverity.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => setState(() => _filterSeverity = ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SeverityBadge(
                              severity: _filterSeverity, compact: true),
                          const SizedBox(width: 6),
                          const Icon(Icons.close, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),

              // Stats bar
              Positioned(
                bottom: _selectedHazard != null ? 200 : 16,
                left: 16,
                right: 16,
                child: _MapStatsBar(hazards: filtered),
              ),

              // Selected hazard panel
              if (_selectedHazard != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _HazardDetailPanel(
                    hazard: _selectedHazard!,
                    onClose: () =>
                        setState(() => _selectedHazard = null),
                    onViewDetails: () => context.push(
                        '${AppRoutes.incidentDetail}?id=${_selectedHazard!.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(HazardModel hazard) {
    final color = _markerColor(hazard.severity);
    final isSelected = _selectedHazard?.id == hazard.id;

    return Marker(
      point: LatLng(hazard.latitude, hazard.longitude),
      width: isSelected ? 50 : 42,
      height: isSelected ? 50 : 42,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedHazard = hazard);
          _mapController.move(
            LatLng(hazard.latitude, hazard.longitude),
            12,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 3 : 1,
              ),
            ],
          ),
          child: Icon(
            hazard.severity == HazardSeverity.critical
                ? Icons.dangerous
                : Icons.warning_amber_rounded,
            color: Colors.white,
            size: isSelected ? 26 : 22,
          ),
        ),
      ),
    );
  }

  Color _markerColor(String severity) {
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

class _MapStatsBar extends StatelessWidget {
  final List<HazardModel> hazards;
  const _MapStatsBar({required this.hazards});

  @override
  Widget build(BuildContext context) {
    final critical =
        hazards.where((h) => h.severity == HazardSeverity.critical).length;
    final high =
        hazards.where((h) => h.severity == HazardSeverity.high).length;
    final medium =
        hazards.where((h) => h.severity == HazardSeverity.medium).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatDot(
              count: hazards.length,
              label: 'Total',
              color: AppColors.primaryDeep),
          _StatDot(count: critical, label: 'Critical', color: AppColors.severityCritical),
          _StatDot(count: high, label: 'High', color: AppColors.severityHigh),
          _StatDot(
              count: medium, label: 'Medium', color: AppColors.severityMedium),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatDot(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }
}

class _HazardDetailPanel extends StatelessWidget {
  final HazardModel hazard;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _HazardDetailPanel({
    required this.hazard,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hazard.hazardType,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              Row(
                children: [
                  SeverityBadge(severity: hazard.severity),
                  const SizedBox(width: 8),
                  StatusChip(status: hazard.incidentStatus),
                  const SizedBox(width: 8),
                  VerificationChip(status: hazard.verificationStatus),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hazard.locationName ??
                          '${hazard.latitude.toStringAsFixed(4)}, ${hazard.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConfidenceMeter(confidence: hazard.confidenceScore),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View Incident Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
