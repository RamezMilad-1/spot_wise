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
import '../../widgets/state_views.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  Future<void> _viewSpot(BuildContext context, Report report) async {
    final spot = await services.backend.getSpot(report.spotId);
    if (spot != null && context.mounted) {
      Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminP = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: adminP.loading && adminP.reports.isEmpty
          ? const LoadingView()
          : adminP.reports.isEmpty
              ? const EmptyView(
                  icon: Icons.flag_outlined,
                  title: 'No reports',
                  message: 'Reported spots will appear here for review.',
                )
              : RefreshIndicator(
                  onRefresh: () => adminP.load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: adminP.reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final r = adminP.reports[i];
                      return _ReportCard(
                        report: r,
                        onView: () => _viewSpot(context, r),
                        onDismiss: () => adminP.resolveReport(r, ReportStatus.dismissed),
                        onAction: () => adminP.resolveReport(r, ReportStatus.reviewed),
                      );
                    },
                  ),
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
                const Icon(Icons.flag_rounded, color: AppColors.danger, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(report.spotName, style: text.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.16),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(report.status.label,
                      style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(report.reason, style: text.bodyMedium),
            const SizedBox(height: 4),
            Text('By ${report.userName} · ${Formatters.relative(report.createdAt)}', style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(onPressed: onView, child: const Text('View spot')),
                const Spacer(),
                if (isOpen) ...[
                  TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
                  FilledButton(onPressed: onAction, child: const Text('Mark actioned')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
