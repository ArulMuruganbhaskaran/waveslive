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

class VerificationHistoryScreen extends ConsumerWidget {
  const VerificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final historyAsync = ref.watch(verificationHistoryProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification History'),
        backgroundColor: AppColors.volunteerColor,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) {
          if (reports.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No History',
              subtitle: 'Your verification history will appear here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, idx) {
              final report = reports[idx];
              final myVerif = report.verifications
                  .where((v) => v.verifierId == user?.id)
                  .firstOrNull;
              return _HistoryCard(report: report, myVerification: myVerif);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ReportModel report;
  final VerificationEntryModel? myVerification;

  const _HistoryCard({required this.report, this.myVerification});

  Color get _resultColor {
    switch (myVerification?.result) {
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

  String get _resultLabel {
    switch (myVerification?.result) {
      case VerificationResult.genuine:
        return 'Genuine';
      case VerificationResult.suspicious:
        return 'Suspicious';
      case VerificationResult.falsified:
        return 'False';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(
            '${AppRoutes.verificationDetail}?reportId=${report.id}'),
        borderRadius: BorderRadius.circular(16),
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
                          report.displayId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          report.processingResult?.hazardType ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _resultColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _resultColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      'My verdict: $_resultLabel',
                      style: TextStyle(
                        color: _resultColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (myVerification?.comment != null) ...[
                const SizedBox(height: 8),
                Text(
                  '"${myVerification!.comment}"',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    myVerification != null
                        ? DateFormat('dd MMM yyyy, HH:mm')
                            .format(myVerification!.verifiedAt)
                        : '',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                  const Spacer(),
                  VerificationChip(
                      status: report.verificationStatus, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
