import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/categories.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/spot.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/choice_chip_row.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/state_views.dart';

class AdminPendingScreen extends StatefulWidget {
  const AdminPendingScreen({super.key});

  @override
  State<AdminPendingScreen> createState() => _AdminPendingScreenState();
}

class _AdminPendingScreenState extends State<AdminPendingScreen> {
  /// First-come, first-served by default — fair to contributors.
  bool _oldestFirst = true;
  String? _categoryId;

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
    final all = adminP.pending;
    final pending =
        all
            .where((s) => _categoryId == null || s.categoryId == _categoryId)
            .toList()
          ..sort(
            (a, b) => _oldestFirst
                ? a.createdAt.compareTo(b.createdAt)
                : b.createdAt.compareTo(a.createdAt),
          );
    final categoryIds = {for (final s in all) s.categoryId}.toList()
      ..sort((a, b) => Categories.labelFor(a).compareTo(Categories.labelFor(b)));
    int byCategory(String id) => all.where((s) => s.categoryId == id).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation queue'),
        actions: [
          IconButton(
            tooltip: _oldestFirst ? 'Oldest first' : 'Newest first',
            icon: Icon(
              _oldestFirst ? Icons.history_rounded : Icons.schedule_rounded,
            ),
            onPressed: () => setState(() => _oldestFirst = !_oldestFirst),
          ),
        ],
      ),
      body: adminP.loading && all.isEmpty
          ? const LoadingView()
          : all.isEmpty
          ? const EmptyView(
              icon: Icons.verified_rounded,
              title: 'All clear',
              message: 'No spots are awaiting review right now.',
            )
          : Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                if (categoryIds.length > 1)
                  ChoiceChipRow<String?>(
                    selected: _categoryId,
                    onSelected: (v) => setState(() => _categoryId = v),
                    options: [
                      ChipOption(null, 'All', count: all.length),
                      for (final id in categoryIds)
                        ChipOption(
                          id,
                          Categories.labelFor(id),
                          count: byCategory(id),
                          icon: Categories.iconFor(id),
                        ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${pending.length} awaiting review · '
                        '${_oldestFirst ? 'oldest' : 'newest'} first',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: pending.isEmpty
                      ? const EmptyView(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'Nothing here',
                          message: 'No pending spots in this category.',
                        )
                      : RefreshIndicator(
                          onRefresh: () => adminP.load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: pending.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.lg),
                            itemBuilder: (_, i) => _PendingCard(
                              spot: pending[i],
                              onApprove: () => _approve(context, pending[i]),
                              onReject: () => _reject(context, pending[i]),
                              onEdit: () => _edit(context, pending[i]),
                              onDelete: () => _delete(context, pending[i]),
                            ),
                          ),
                        ),
                ),
              ],
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
