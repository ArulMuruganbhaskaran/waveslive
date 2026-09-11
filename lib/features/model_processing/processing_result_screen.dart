import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../models/report_model.dart';

class ProcessingResultScreen extends ConsumerStatefulWidget {
  final String reportId;
  const ProcessingResultScreen({super.key, required this.reportId});

  @override
  ConsumerState<ProcessingResultScreen> createState() =>
      _ProcessingResultScreenState();
}

class _ProcessingResultScreenState
    extends ConsumerState<ProcessingResultScreen>
    with SingleTickerProviderStateMixin {
  ReportModel? _report;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Poll for AI result completion (max ~12 s)
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 8;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadReport();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    final service = ref.read(dataAcquisitionServiceProvider);
    final report = await service.getReportById(widget.reportId);
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
      _animController.forward();
      // Start polling if AI result not yet available
      if (report?.processingStatus != ProcessingStatus.completed &&
          report?.processingStatus != ProcessingStatus.failed) {
        _startPolling();
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1500 ~/ 1000), (_) async {
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        return;
      }
      _pollCount++;
      final service = ref.read(dataAcquisitionServiceProvider);
      final report = await service.getReportById(widget.reportId);
      if (!mounted) return;
      if (report != null &&
          (report.processingStatus == ProcessingStatus.completed ||
              report.processingStatus == ProcessingStatus.failed)) {
        _pollTimer?.cancel();
        setState(() => _report = report);
      } else if (report != null) {
        setState(() => _report = report);
      }
    });
  }

  bool get _processingDone =>
      _report?.processingStatus == ProcessingStatus.completed ||
      _report?.processingStatus == ProcessingStatus.failed;

  bool get _hasFailed =>
      _report?.processingStatus == ProcessingStatus.failed;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final report = _report;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ── Animated Icon ───────────────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.oceanGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMid.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Headline ────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Report Submitted!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your response has been submitted successfully and is currently under review by our coastal officers.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Report ID chip ──────────────────────────────────────────
              if (report != null)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Report ID: ${report.displayId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ── AI Result card (shown when processing completes) ─────────
              if (_processingDone && report != null)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _hasFailed
                      ? _ProcessingFailedCard()
                      : _AIResultCard(report: report),
                )
              else ...[
                // ── Status steps (while still processing) ─────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _StatusStepsCard(),
                ),
              ],

              const Spacer(),

              // ── Buttons ─────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.agentDashboard),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.agentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.dashboard_outlined),
                        label: const Text(
                          'Back to Dashboard',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.myReports),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.agentColor,
                          side: const BorderSide(color: AppColors.agentColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.list_alt_outlined),
                        label: const Text('View My Reports'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Result Card — shown when processing is complete
// ─────────────────────────────────────────────────────────────────────────────

class _AIResultCard extends StatelessWidget {
  final ReportModel report;
  const _AIResultCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final result = report.processingResult!;
    final hazardDetected = result.hazardDetected;

    final Color accentColor = hazardDetected
        ? _severityColor(result.severity)
        : const Color(0xFF1A7A4A);

    final String statusIcon = hazardDetected ? '⚠️' : '✅';
    final String statusLabel =
        hazardDetected ? result.hazardType : 'No Hazard Detected';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Analysis Result',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Confidence chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.confidencePercentage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Status line
          Row(
            children: [
              Text(statusIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              if (hazardDetected)
                _SeverityBadge(severity: result.severity),
            ],
          ),

          const SizedBox(height: 12),

          // Observation
          Text(
            result.observation,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 12),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: accentColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.recommendation,
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
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
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case HazardSeverity.critical:
        return const Color(0xFFDC2626);
      case HazardSeverity.high:
        return const Color(0xFFEA580C);
      case HazardSeverity.medium:
        return const Color(0xFFCA8A04);
      default:
        return const Color(0xFF16A34A);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Processing Failed Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProcessingFailedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing Failed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'AI analysis could not be completed. An officer will review manually.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Steps Card — shown while AI is still processing
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What happens next?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _StatusStep(
            icon: Icons.check_circle,
            label: 'Report submitted',
            color: AppColors.statusResolved,
            isDone: true,
          ),
          _StatusStep(
            icon: Icons.auto_awesome,
            label: 'AI model processing image',
            color: AppColors.accent,
            isDone: false,
            isActive: true,
          ),
          _StatusStep(
            icon: Icons.verified_user_outlined,
            label: 'Volunteer verification',
            color: AppColors.volunteerColor,
            isDone: false,
          ),
          _StatusStep(
            icon: Icons.security_outlined,
            label: 'Officer review & action',
            color: AppColors.primaryDeep,
            isDone: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Severity Badge
// ─────────────────────────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (severity) {
      case HazardSeverity.critical:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      case HazardSeverity.high:
        bg = const Color(0xFFFEECE8);
        fg = const Color(0xFFEA580C);
        break;
      case HazardSeverity.medium:
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFFCA8A04);
        break;
      default:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Step Widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.color,
    this.isDone = false,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? color
                    : isActive
                        ? color.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                border: isActive
                    ? Border.all(color: color, width: 2)
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check : icon,
                size: 16,
                color: isDone
                    ? Colors.white
                    : isActive
                        ? color
                        : AppColors.textHint,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: AppColors.surfaceVariant,
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isDone || isActive ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
