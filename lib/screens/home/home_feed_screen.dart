import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../models/spot.dart';
import '../../models/spot_filter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_store.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/app_menu_button.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/max_width.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/spot_card.dart';
import '../../widgets/state_views.dart';
import '../map/filter_sheet.dart';
import '../shell/home_shell.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  static const Distance _distance = Distance();

  SpotFilter _filter = const SpotFilter();
  LatLng? _origin;
  String? _placeLabel;

  void _toggleCategory(String categoryId) {
    final ids = {..._filter.categoryIds};
    ids.contains(categoryId) ? ids.remove(categoryId) : ids.add(categoryId);
    setState(() => _filter = _filter.copyWith(categoryIds: ids));
  }

  Future<void> _pickLocation() async {
    final picked = await pickLocation(context);
    if (picked != null && mounted) {
      setState(() {
        _origin = picked.$1;
        _placeLabel = picked.$2;
      });
    }
  }

  void _clearLocation() => setState(() {
    _origin = null;
    _placeLabel = null;
  });

  double _distM(Spot s) => _distance.as(LengthUnit.Meter, _origin!, s.latLng);

  Future<void> _openFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        initial: _filter,
        onApply: (f) => setState(() => _filter = f),
      ),
    );
  }

  Future<void> _openSearch() async {
    final result = await Navigator.pushNamed(context, AppRoutes.search);
    if (result == 'map' && mounted) context.read<HomeTab>().go(1);
  }

  Future<void> _toggleSave(Spot spot) async {
    if (await ensureLoggedIn(context) && mounted) {
      context.read<AuthProvider>().toggleSave(spot.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final spotsP = context.watch<SpotsProvider>();
    final firstName = (auth.user?.name ?? 'there').split(' ').first;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
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
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
          const NotificationBell(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => spotsP.load(force: true),
        child: MaxWidthBox(child: _buildBody(context, spotsP, auth)),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SpotsProvider spotsP,
    AuthProvider auth,
  ) {
    if (spotsP.loading && spotsP.isEmpty) return const SpotFeedSkeleton();
    if (spotsP.error != null && spotsP.isEmpty) {
      return ErrorView(
        message: spotsP.error!,
        onRetry: () => spotsP.load(force: true),
      );
    }

    final hasLocation = _origin != null;
    final filtering = _filter.isActive;
    final activeMode = hasLocation || filtering;

    var results = spotsP.spots.where((s) => _filter.matches(s)).toList();
    if (hasLocation) {
      results.sort((a, b) => _distM(a).compareTo(_distM(b)));
    }
    final recommended = spotsP.recommendationsFor(auth.user, limit: 8);
    final featured = spotsP.featured;

    return ListView(
      // Clear the floating dock (its height is injected into the bottom
      // MediaQuery padding by the shell's extendBody).
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      children: [
        const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(child: _SearchBarButton(onTap: _openSearch)),
              const SizedBox(width: AppSpacing.sm),
              _FilterButton(count: _filter.activeCount, onTap: _openFilters),
            ],
          ),
        ),
        _CategoryStrip(
          selected: _filter.categoryIds,
          onToggle: _toggleCategory,
        ),
        _LocationBar(
          label: _placeLabel,
          onTap: _pickLocation,
          onClear: _clearLocation,
        ),

        if (activeMode) ...[
          if (hasLocation)
            SectionHeader(
              title: 'Closest near $_placeLabel',
              subtitle:
                  '${results.length} ${results.length == 1 ? 'spot' : 'spots'} · sorted by distance'
                  '${filtering ? ' · filtered' : ''}',
            )
          else
            _ActiveFilterBar(
              count: results.length,
              onClear: () => setState(() => _filter = const SpotFilter()),
            ),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: EmptyView(
                icon: Icons.filter_alt_off_rounded,
                title: 'No matches',
                message:
                    'Try another category, a wider area, or clear your filters.',
              ),
            )
          else
            ...results.map(
              (spot) => _spotCard(
                context,
                spot,
                auth,
                distance: hasLocation ? _distM(spot) : null,
              ),
            ),
        ] else ...[
          if (featured.isNotEmpty) ...[
            const SectionHeader(
              title: 'Featured',
              subtitle: 'Hand-picked by the SpotWise team',
            ),
            _rail(context, featured, auth),
          ],
          if (recommended.isNotEmpty) ...[
            SectionHeader(
              title: 'Recommended for you',
              subtitle: auth.user?.interests.isNotEmpty == true
                  ? 'Based on ${auth.user!.interests.take(2).join(' & ').toLowerCase()}'
                  : 'Top-rated places to start',
            ),
            _rail(context, recommended, auth),
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
            ...results.map((spot) => _spotCard(context, spot, auth)),
        ],
      ],
    );
  }

  Widget _spotCard(
    BuildContext context,
    Spot spot,
    AuthProvider auth, {
    double? distance,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: SpotCard(
      spot: spot,
      isSaved: auth.isSaved(spot.id),
      onToggleSave: () => _toggleSave(spot),
      distanceMeters: distance,
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot),
    ),
  );

  /// Horizontal rail of editorial overlay cards (Featured / Recommended).
  Widget _rail(BuildContext context, List<Spot> spots, AuthProvider auth) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        itemCount: spots.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final spot = spots[i];
          return SizedBox(
            width: 270,
            child: SpotOverlayCard(
              spot: spot,
              isSaved: auth.isSaved(spot.id),
              onToggleSave: () => _toggleSave(spot),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.spotDetails,
                arguments: spot,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  final String? label;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _LocationBar({
    required this.label,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      0,
    );
    if (label == null) {
      return Padding(
        padding: padding,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.near_me_outlined, size: 18),
          label: const Text('Search a location for nearby spots'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            alignment: Alignment.centerLeft,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: AppColors.teal,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Near $label',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onClear,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  const _ActiveFilterBar({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'result' : 'results'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

class _SearchBarButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(AppRadius.pill));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 15,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Where are you going?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The circular filter button beside the search bar (with an active-count badge).
class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkInk : AppColors.ink,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: Icon(
              Icons.tune_rounded,
              color: isDark ? AppColors.darkBg : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _CategoryStrip({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryStore>().enabled;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final c = categories[i];
          final isSelected = selected.contains(c.id);
          final scheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final selectedFill = isDark ? AppColors.darkInk : AppColors.ink;
          final selectedIcon = isDark ? AppColors.darkBg : Colors.white;
          return InkWell(
            onTap: () => onToggle(c.id),
            borderRadius: AppRadius.brLg,
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedFill
                        : scheme.surfaceContainerHighest,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Icon(
                    c.icon,
                    color: isSelected ? selectedIcon : c.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
