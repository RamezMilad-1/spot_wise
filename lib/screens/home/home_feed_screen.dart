import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/spot.dart';
import '../../models/spot_filter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_store.dart';
import '../../providers/map_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/spot_card.dart';
import '../../widgets/state_views.dart';
import '../shell/home_shell.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  void _openCategory(BuildContext context, String categoryId) {
    context.read<MapProvider>().setFilter(SpotFilter(categoryIds: {categoryId}));
    context.read<HomeTab>().go(1);
  }

  Future<void> _openSearch(BuildContext context) async {
    final result = await Navigator.pushNamed(context, AppRoutes.search);
    if (result == 'map' && context.mounted) context.read<HomeTab>().go(1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final spotsP = context.watch<SpotsProvider>();
    final firstName = (auth.user?.name ?? 'there').split(' ').first;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $firstName 👋', style: text.bodySmall),
            Text('Find your next spot', style: text.titleLarge),
          ],
        ),
        actions: [
          if (auth.role.canModerate)
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Admin',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
          const NotificationBell(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => spotsP.load(force: true),
        child: _buildBody(context, spotsP, auth),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SpotsProvider spotsP, AuthProvider auth) {
    if (spotsP.loading && spotsP.isEmpty) return const SpotFeedSkeleton();
    if (spotsP.error != null && spotsP.isEmpty) {
      return ErrorView(message: spotsP.error!, onRetry: () => spotsP.load(force: true));
    }

    final recommended = spotsP.recommendationsFor(auth.user, limit: 8);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: _SearchBarButton(onTap: () => _openSearch(context)),
        ),
        _CategoryStrip(onTap: (id) => _openCategory(context, id)),
        if (recommended.isNotEmpty) ...[
          SectionHeader(
            title: 'Recommended for you',
            subtitle: auth.user?.interests.isNotEmpty == true
                ? 'Based on ${auth.user!.interests.take(2).join(' & ').toLowerCase()}'
                : 'Top-rated places to start',
          ),
          SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: recommended.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _MiniSpotCard(spot: recommended[i]),
            ),
          ),
        ],
        SectionHeader(
          title: 'Explore spots',
          subtitle: '${spotsP.spots.length} community-approved places',
        ),
        if (spotsP.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: EmptyView(
              icon: Icons.travel_explore_rounded,
              title: 'No spots yet',
              message: 'Approved community spots will appear here.',
            ),
          )
        else
          ...spotsP.spots.map((spot) => Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                child: SpotCard(
                  spot: spot,
                  isSaved: auth.isSaved(spot.id),
                  onToggleSave: auth.isLoggedIn ? () => auth.toggleSave(spot.id) : null,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot),
                ),
              )),
      ],
    );
  }
}

class _SearchBarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Text('Where are you going?',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _CategoryStrip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryStore>().enabled;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final c = categories[i];
          return InkWell(
            onTap: () => onTap(c.id),
            borderRadius: AppRadius.brMd,
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.14),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(c.icon, color: c.color),
                ),
                const SizedBox(height: 6),
                Text(c.label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniSpotCard extends StatelessWidget {
  final Spot spot;
  const _MiniSpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  NetworkPhoto(spot.coverPhoto, width: 220, height: 130),
                  if (spot.hiddenGem)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(spot.location, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    RatingStars(spot.rating, size: 13, showValue: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
