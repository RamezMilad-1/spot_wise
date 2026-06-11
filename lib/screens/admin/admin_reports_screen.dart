import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/report.dart';
import '../../providers/admin_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/choice_chip_row.dart';
import '../../widgets/state_views.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ReportStatus? _status;

  Future<void> _viewSpot(BuildContext context, Report report) async {
    final spot = await services.backend.getSpot(report.spotId);
    if (spot != null && context.mounted) {
      Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminP = context.watch<AdminProvider>();
    final all = adminP.reports;
    // Open reports first, newest first within each group.
    final reports =
        all.where((r) => _status == null || r.status == _status).toList()
          ..sort((a, b) {
            final aOpen = a.status == ReportStatus.open ? 0 : 1;
            final bOpen = b.status == ReportStatus.open ? 0 : 1;
            if (aOpen != bOpen) return aOpen.compareTo(bOpen);
            return b.createdAt.compareTo(a.createdAt);
          });

    int byStatus(ReportStatus s) => all.where((r) => r.status == s).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: adminP.loading && all.isEmpty
          ? const LoadingView()
          : all.isEmpty
          ? const EmptyView(
              icon: Icons.flag_outlined,
              title: 'No reports',
              message: 'Reported spots will appear here for review.',
            )
          : Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                ChoiceChipRow<ReportStatus?>(
                  selected: _status,
                  onSelected: (v) => setState(() => _status = v),
                  options: [
                    ChipOption(null, 'All', count: all.length),
                    for (final s in ReportStatus.values)
                      ChipOption(s, s.label, count: byStatus(s)),
                  ],
                ),
                Expanded(
                  child: reports.isEmpty
                      ? const EmptyView(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'Nothing here',
                          message: 'No reports with this status.',
                        )
                      : RefreshIndicator(
                          onRefresh: () => adminP.load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: reports.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (_, i) {
                              final r = reports[i];
                              return _ReportCard(
                                report: r,
                                onView: () => _viewSpot(context, r),
                                onDismiss: () => adminP.resolveReport(
                                  r,
                                  ReportStatus.dismissed,
                                ),
                                onAction: () => adminP.resolveReport(
                                  r,
                                  ReportStatus.reviewed,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onView;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  const _ReportCard({
    required this.report,
    required this.onView,
    required this.onDismiss,
    required this.onAction,
  });

  Color get _statusColor => switch (report.status) {
    ReportStatus.open => AppColors.warning,
    ReportStatus.reviewed => AppColors.success,
    ReportStatus.dismissed => AppColors.inkFaint,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isOpen = report.status == ReportStatus.open;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(report.spotName, style: text.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.16),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    report.status.label,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(report.reason, style: text.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'By ${report.userName} · ${Formatters.relative(report.createdAt)}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(onPressed: onView, child: const Text('View spot')),
                const Spacer(),
                if (isOpen) ...[
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                  FilledButton(
                    onPressed: onAction,
                    child: const Text('Mark actioned'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
