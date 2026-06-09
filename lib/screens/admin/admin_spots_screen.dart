import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/spot.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/badges.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/state_views.dart';

/// Full spot management for admins: search every spot (any status), edit,
/// delete, and toggle verified / featured.
class AdminSpotsScreen extends StatefulWidget {
  const AdminSpotsScreen({super.key});

  @override
  State<AdminSpotsScreen> createState() => _AdminSpotsScreenState();
}

class _AdminSpotsScreenState extends State<AdminSpotsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadAllSpots());
  }

  Future<void> _delete(Spot spot) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete “${spot.name}”?',
      message: 'This permanently removes the spot for everyone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<AdminProvider>().deleteSpot(spot);
    if (mounted) AppSnackbar.show(context, 'Spot deleted.');
  }

  Future<void> _edit(Spot spot) async {
    await Navigator.pushNamed(context, AppRoutes.editSpot, arguments: spot);
    if (mounted) context.read<AdminProvider>().loadAllSpots();
  }

  @override
  Widget build(BuildContext context) {
    final adminP = context.watch<AdminProvider>();
    final q = _query.trim().toLowerCase();
    final spots = q.isEmpty
        ? adminP.allSpots
        : adminP.allSpots
            .where((s) => '${s.name} ${s.city} ${s.country}'.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage spots')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search by name, city or country',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: adminP.loadingAll && adminP.allSpots.isEmpty
                ? const LoadingView()
                : spots.isEmpty
                    ? const EmptyView(
                        icon: Icons.search_off_rounded,
                        title: 'No spots',
                        message: 'Nothing matches your search yet.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => adminP.loadAllSpots(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                          itemCount: spots.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) => _AdminSpotCard(
                            spot: spots[i],
                            onEdit: () => _edit(spots[i]),
                            onDelete: () => _delete(spots[i]),
                            onToggleFeatured: () =>
                                context.read<AdminProvider>().toggleFeatured(spots[i]),
                            onToggleVerified: () =>
                                context.read<AdminProvider>().toggleVerified(spots[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AdminSpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFeatured;
  final VoidCallback onToggleVerified;

  const _AdminSpotCard({
    required this.spot,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFeatured,
    required this.onToggleVerified,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkPhoto(spot.coverPhoto, width: 56, height: 56, radius: AppRadius.brSm),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(spot.location, style: text.bodySmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusBadge(spot.status),
                      if (spot.featured)
                        const Pill(label: 'Featured', icon: Icons.star_rounded, color: AppColors.amber),
                      if (spot.verified) const VerifiedBadge(),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit();
                  case 'feature':
                    onToggleFeatured();
                  case 'verify':
                    onToggleVerified();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'feature', child: Text(spot.featured ? 'Unfeature' : 'Feature on home')),
                PopupMenuItem(value: 'verify', child: Text(spot.verified ? 'Remove verified' : 'Mark verified')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
