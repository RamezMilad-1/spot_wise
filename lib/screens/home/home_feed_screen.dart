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
import '../../widgets/network_photo.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/rating_stars.dart';
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
              onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
          IconButton(
            tooltip: 'Filter',
            icon: Badge(
              isLabelVisible: _filter.activeCount > 0,
              label: Text('${_filter.activeCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: _openFilters,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: _SearchBarButton(onTap: _openSearch),
        ),
        _CategoryStrip(selected: _filter.categoryIds, onToggle: _toggleCategory),
        _LocationBar(label: _placeLabel, onTap: _pickLocation, onClear: _clearLocation),

        if (activeMode) ...[
          if (hasLocation)
            SectionHeader(
              title: 'Closest near $_placeLabel',
              subtitle: '${results.length} ${results.length == 1 ? 'spot' : 'spots'} · sorted by distance'
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
                message: 'Try another category, a wider area, or clear your filters.',
              ),
            )
          else
            ...results.map((spot) =>
                _spotCard(context, spot, auth, distance: hasLocation ? _distM(spot) : null)),
        ] else ...[
          if (featured.isNotEmpty) ...[
            const SectionHeader(
              title: 'Featured',
              subtitle: 'Hand-picked by the SpotWise team',
            ),
            _MiniRail(spots: featured),
          ],
          if (recommended.isNotEmpty) ...[
            SectionHeader(
              title: 'Recommended for you',
              subtitle: auth.user?.interests.isNotEmpty == true
                  ? 'Based on ${auth.user!.interests.take(2).join(' & ').toLowerCase()}'
                  : 'Top-rated places to start',
            ),
            _MiniRail(spots: recommended),
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

  Widget _spotCard(BuildContext context, Spot spot, AuthProvider auth, {double? distance}) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        child: SpotCard(
          spot: spot,
          isSaved: auth.isSaved(spot.id),
          onToggleSave: () => _toggleSave(spot),
          distanceMeters: distance,
          onTap: () => Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot),
        ),
      );
}

class _LocationBar extends StatelessWidget {
  final String? label;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _LocationBar({required this.label, required this.onTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final padding = const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0);
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
    return Padding(
      padding: padding,
      child: Material(
        color: AppColors.tealMist.withValues(alpha: 0.5),
        borderRadius: AppRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, size: 18, color: AppColors.tealDark),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Near $label',
                    style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onClear,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.tealDark),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        children: [
          Text('$count ${count == 1 ? 'result' : 'results'}',
              style: Theme.of(context).textTheme.titleSmall),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final c = categories[i];
          final isSelected = selected.contains(c.id);
          return InkWell(
            onTap: () => onToggle(c.id),
            borderRadius: AppRadius.brMd,
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSelected ? c.color : c.color.withValues(alpha: 0.14),
                    borderRadius: AppRadius.brMd,
                    border: isSelected ? Border.all(color: c.color, width: 2) : null,
                  ),
                  child: Icon(c.icon, color: isSelected ? Colors.white : c.color),
                ),
                const SizedBox(height: 6),
                Text(c.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : null,
                        )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniRail extends StatelessWidget {
  final List<Spot> spots;
  const _MiniRail({required this.spots});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: spots.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => _MiniSpotCard(spot: spots[i]),
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
