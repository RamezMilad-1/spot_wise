import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/spot.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/state_views.dart';

class AdminPendingScreen extends StatelessWidget {
  const AdminPendingScreen({super.key});

  Future<void> _approve(BuildContext context, Spot spot) async {
    await context.read<AdminProvider>().approve(spot);
    if (context.mounted) {
      AppSnackbar.success(context, '“${spot.name}” approved and published.');
    }
  }

  Future<void> _reject(BuildContext context, Spot spot) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject submission'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason (sent to the contributor)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty && context.mounted) {
      await context.read<AdminProvider>().reject(spot, reason);
      if (context.mounted) {
        AppSnackbar.show(context, '“${spot.name}” rejected.');
      }
    }
  }

  Future<void> _edit(BuildContext context, Spot spot) async {
    await Navigator.pushNamed(context, AppRoutes.editSpot, arguments: spot);
    if (context.mounted) context.read<AdminProvider>().load();
  }

  Future<void> _delete(BuildContext context, Spot spot) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete “${spot.name}”?',
      message: 'This permanently removes the submission.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await context.read<AdminProvider>().deleteSpot(spot);
    if (context.mounted) AppSnackbar.show(context, '“${spot.name}” deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final adminP = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Moderation queue')),
      body: adminP.loading && adminP.pending.isEmpty
          ? const LoadingView()
          : adminP.pending.isEmpty
          ? const EmptyView(
              icon: Icons.verified_rounded,
              title: 'All clear',
              message: 'No spots are awaiting review right now.',
            )
          : RefreshIndicator(
              onRefresh: () => adminP.load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: adminP.pending.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (_, i) => _PendingCard(
                  spot: adminP.pending[i],
                  onApprove: () => _approve(context, adminP.pending[i]),
                  onReject: () => _reject(context, adminP.pending[i]),
                  onEdit: () => _edit(context, adminP.pending[i]),
                  onDelete: () => _delete(context, adminP.pending[i]),
                ),
              ),
            ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PendingCard({
    required this.spot,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkPhoto(spot.coverPhoto, width: double.infinity, height: 150),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(spot.name, style: text.titleMedium)),
                    CategoryChip(spot.categoryId),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${spot.location} · by ${spot.submittedByName}',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  spot.description,
                  style: text.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        'Approve',
                        icon: Icons.check_rounded,
                        onPressed: onApprove,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.outline(
                        'Reject',
                        icon: Icons.close_rounded,
                        onPressed: onReject,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.spotDetails,
                        arguments: spot,
                      ),
                      child: const Text('View'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
