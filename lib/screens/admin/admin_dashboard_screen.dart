import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/admin_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/spot_list_tile.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final adminP = context.watch<AdminProvider>();
    final spotsP = context.watch<SpotsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: RefreshIndicator(
        onRefresh: () => adminP.load(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                _StatCard(
                  value: '${adminP.pendingCount}',
                  label: 'Pending',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.adminPending),
                ),
                _StatCard(
                  value: '${adminP.openReportCount}',
                  label: 'Reports',
                  icon: Icons.flag_rounded,
                  color: AppColors.danger,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.adminReports),
                ),
                _StatCard(
                  value: '${spotsP.spots.length}',
                  label: 'Live spots',
                  icon: Icons.public_rounded,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ActionTile(
              icon: Icons.fact_check_outlined,
              title: 'Moderation queue',
              subtitle: '${adminP.pendingCount} spots awaiting review',
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminPending),
            ),
            _ActionTile(
              icon: Icons.flag_outlined,
              title: 'Reports',
              subtitle: '${adminP.openReportCount} open',
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminReports),
            ),
            _ActionTile(
              icon: Icons.category_outlined,
              title: 'Categories',
              subtitle: 'Enable or disable spot categories',
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminCategories),
            ),
            if (adminP.pending.isNotEmpty) ...[
              const SectionHeader(title: 'Latest submissions'),
              for (final spot in adminP.pending.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: SpotListTile(
                    spot: spot,
                    subtitleOverride: 'By ${spot.submittedByName} · ${spot.location}',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.adminPending),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.brMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: AppSpacing.sm),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: Icon(icon, color: AppColors.teal),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
