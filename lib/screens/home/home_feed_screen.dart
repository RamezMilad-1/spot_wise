import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/utils/country_flags.dart';
import '../../core/utils/formatters.dart';
import '../../models/spot.dart';
import '../../models/spot_filter.dart';
import '../../providers/ai_planner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_store.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_menu_button.dart';
import '../../widgets/destination_picker_sheet.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/max_width.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/spot_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';
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
        // "Near a place" and a destination would fight each other (Near Paris
        // + Germany = no results) — the newer choice wins.
        _filter = _filter.copyWith(country: '', city: '');
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

  /// Opens the country → city cascade (with free-text search). [cityFirst]
  /// jumps straight to the cities of the already-chosen country.
  Future<void> _pickDestination({bool cityFirst = false}) async {
    final spotsP = context.read<SpotsProvider>();
    final picked = await showDestinationPicker(
      context,
      countries: spotsP.countryCounts,
      citiesFor: spotsP.cityCountsFor,
      spots: spotsP.spots,
      country: _filter.country,
      city: _filter.city,
      startOnCities: cityFirst,
    );
    if (picked == null || !mounted) return;
    if (picked.spot != null) {
      Navigator.pushNamed(context, AppRoutes.spotDetails,
          arguments: picked.spot);
      return;
    }
    setState(() {
      _filter = _filter.copyWith(country: picked.country, city: picked.city);
      // A destination and "near a place" would fight each other (Near Paris
      // + Germany = no results) — the newer choice wins.
      if (picked.country.isNotEmpty) {
        _origin = null;
        _placeLabel = null;
      }
    });
  }

  Future<void> _toggleSave(Spot spot) async {
    if (await ensureLoggedIn(context) && mounted) {
      context.read<AuthProvider>().toggleSave(spot.id);
    }
  }

  /// Human label for the active destination — the city when one is chosen,
  /// else the country.
  String get _destinationPlace =>
      _filter.city.isNotEmpty ? _filter.city : _filter.country;

  /// Pre-fills the AI planner with the active destination and jumps to the
  /// Plan tab.
  void _planTrip() {
    final hasCity = _filter.city.isNotEmpty;
    context.read<AiPlannerProvider>().prefillDestination(
      destination: hasCity ? _filter.city : _filter.country,
      country: hasCity ? _filter.country : '',
    );
    context.read<HomeTab>().go(2);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final spotsP = context.watch<SpotsProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        titleSpacing: 0,
        title: const AppLogo(size: 28),
        actions: [
          if (auth.role.canModerate)
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Admin',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
          const NotificationBell(),
          Center(
            child: Tooltip(
              message: auth.user != null ? 'Profile' : 'Sign in',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    auth.user != null ? AppRoutes.profile : AppRoutes.login,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: UserAvatar(
                      photoUrl: auth.user?.photoUrl,
                      initials: auth.user?.initials ?? '?',
                      radius: 17,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
    } else if (filtering) {
      // Curated feel: best-rated matches first when browsing a destination
      // or category.
      results.sort((a, b) => b.rating.compareTo(a.rating));
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
        _GreetingHeader(
          firstName: auth.user?.name.split(' ').first,
          cityCount: spotsP.cities.length,
          countryCount: spotsP.countryCounts.length,
        ),
        const SizedBox(height: AppSpacing.sm),
        _CategoryStrip(
          selected: _filter.categoryIds,
          onToggle: _toggleCategory,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: _DestinationButton(
                  country: _filter.country,
                  city: _filter.city,
                  onPickCountry: () => _pickDestination(),
                  onPickCity: () => _pickDestination(
                    cityFirst: _filter.country.isNotEmpty,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CircleButton(
                icon: Icons.near_me_rounded,
                tooltip: 'Search near a place',
                onTap: _pickLocation,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CircleButton(
                icon: Icons.tune_rounded,
                count: _filter.activeCount,
                tooltip: 'Filters',
                onTap: _openFilters,
              ),
            ],
          ),
        ),

        if (activeMode) ...[
          _ActiveFilterBar(
            count: results.length,
            filter: _filter,
            placeLabel: _placeLabel,
            onFilter: (f) => setState(() => _filter = f),
            onClearFilters: () => setState(() => _filter = const SpotFilter()),
            onClearLocation: _clearLocation,
          ),
          if (_filter.country.isNotEmpty) ...[
            _PlanTripBanner(place: _destinationPlace, onTap: _planTrip),
            if (results.any((s) => s.featured)) ...[
              SectionHeader(
                title: 'Featured in $_destinationPlace',
                subtitle: 'Hand-picked by the SpotWise team',
              ),
              _rail(context, results.where((s) => s.featured).toList(), auth),
            ],
          ],
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
      heroTag: 'spot-hero-${spot.id}',
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

/// Editorial greeting block: time-of-day greeting + date, a headline that
/// rotates daily, and a live stat line — replaces the old static app-bar
/// "Hello, there" title.
class _GreetingHeader extends StatelessWidget {
  final String? firstName;
  final int cityCount;
  final int countryCount;

  const _GreetingHeader({
    required this.firstName,
    required this.cityCount,
    required this.countryCount,
  });

  static const _prompts = [
    'Where to next',
    'Ready for an adventure',
    'What will you discover',
    'Somewhere new today',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final (greeting, emoji) = switch (now.hour) {
      >= 5 && < 12 => ('Good morning', '☀️'),
      >= 12 && < 17 => ('Good afternoon', '🌤️'),
      _ => ('Good evening', '🌙'),
    };
    // Same prompt all day, a fresh one tomorrow.
    final prompt =
        _prompts[now.difference(DateTime(now.year)).inDays % _prompts.length];
    final headline = firstName == null ? '$prompt?' : '$prompt, $firstName?';

    final stats = [
      if (cityCount > 0) '$cityCount cities',
      if (countryCount > 0) '$countryCount countries',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting $emoji  ·  ${Formatters.weekday(now)}'.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(headline, style: text.headlineMedium),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('$stats — added by travellers', style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Ink-filled call-to-action shown while browsing a destination: hands the
/// place to the AI planner and switches to the Plan tab.
class _PlanTripBanner extends StatelessWidget {
  final String place;
  final VoidCallback onTap;

  const _PlanTripBanner({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkInk : AppColors.ink;
    final fg = isDark ? AppColors.darkBg : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.brCard,
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: bg,
          borderRadius: AppRadius.brCard,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: fg, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan a trip to $place',
                          style: text.titleSmall?.copyWith(color: fg),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Let AI build a day-by-day itinerary',
                          style: text.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Result count + one removable pill per active filter (and the active
/// `Near <place>` location, which lives outside [SpotFilter]).
class _ActiveFilterBar extends StatelessWidget {
  final int count;
  final SpotFilter filter;
  final String? placeLabel;
  final ValueChanged<SpotFilter> onFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onClearLocation;

  const _ActiveFilterBar({
    required this.count,
    required this.filter,
    required this.placeLabel,
    required this.onFilter,
    required this.onClearFilters,
    required this.onClearLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$count ${count == 1 ? 'result' : 'results'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (filter.isActive)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (placeLabel != null)
                _FilterPill(
                  icon: Icons.near_me_rounded,
                  label: 'Near $placeLabel',
                  onRemove: onClearLocation,
                ),
              if (filter.country.isNotEmpty)
                _FilterPill(
                  emoji: countryFlag(filter.country),
                  label: filter.country,
                  // Removing the country also drops its city.
                  onRemove: () => onFilter(
                    filter.copyWith(country: '', city: ''),
                  ),
                ),
              if (filter.city.isNotEmpty)
                _FilterPill(
                  icon: Icons.location_city_rounded,
                  label: filter.city,
                  onRemove: () => onFilter(filter.copyWith(city: '')),
                ),
              if (filter.minRating > 0)
                _FilterPill(
                  label: '★ ${filter.minRating.toStringAsFixed(0)}+',
                  onRemove: () => onFilter(filter.copyWith(minRating: 0)),
                ),
              for (final p in filter.priceRanges)
                _FilterPill(
                  label: p.label,
                  onRemove: () => onFilter(
                    filter.copyWith(
                      priceRanges: {...filter.priceRanges}..remove(p),
                    ),
                  ),
                ),
              if (filter.freeOnly)
                _FilterPill(
                  label: 'Free entry',
                  onRemove: () => onFilter(filter.copyWith(freeOnly: false)),
                ),
              if (filter.familyOnly)
                _FilterPill(
                  label: 'Family',
                  onRemove: () => onFilter(filter.copyWith(familyOnly: false)),
                ),
              if (filter.hiddenGemOnly)
                _FilterPill(
                  label: 'Hidden gems',
                  onRemove: () =>
                      onFilter(filter.copyWith(hiddenGemOnly: false)),
                ),
              if (filter.maxDistanceKm != null)
                _FilterPill(
                  label: '≤ ${filter.maxDistanceKm!.round()} km',
                  onRemove: () =>
                      onFilter(filter.copyWith(clearDistance: true)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A removable stadium pill for one active filter. The whole pill is the
/// (≥44px) tap target that removes it.
class _FilterPill extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final VoidCallback onRemove;

  const _FilterPill({
    this.icon,
    this.emoji,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRemove,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.xs),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.close_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Split destination pill — the home page's "search". The left half picks the
/// country, the right half drills into a city of that country.
class _DestinationButton extends StatelessWidget {
  final String country;
  final String city;
  final VoidCallback onPickCountry;
  final VoidCallback onPickCity;

  const _DestinationButton({
    required this.country,
    required this.city,
    required this.onPickCountry,
    required this.onPickCity,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(AppRadius.pill));

    final hasCountry = country.isNotEmpty;
    final cityLabel = !hasCountry
        ? 'City'
        : city.isEmpty
        ? 'All cities'
        : city;

    Widget half({
      String? leading,
      required String label,
      required bool selected,
      required bool enabled,
      required VoidCallback onTap,
      required String semantics,
      int flex = 1,
    }) {
      final labelStyle = selected
          ? text.titleSmall
          : text.bodyMedium?.copyWith(
              color: enabled ? null : scheme.onSurfaceVariant,
            );
      return Expanded(
        flex: flex,
        child: Semantics(
          button: true,
          label: semantics,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + AppSpacing.xxs,
                vertical: 15,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    Text(leading, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: labelStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            half(
              leading: hasCountry ? countryFlag(country) : '🌍',
              label: hasCountry ? country : 'Country',
              selected: hasCountry,
              enabled: true,
              onTap: onPickCountry,
              semantics: 'Choose country',
              flex: 6,
            ),
            Container(
              width: 1,
              height: 26,
              color: scheme.outline.withValues(alpha: 0.6),
            ),
            half(
              label: cityLabel,
              selected: city.isNotEmpty,
              enabled: hasCountry,
              onTap: onPickCity,
              semantics: 'Choose city',
              flex: 5,
            ),
          ],
        ),
      ),
    );
  }
}

/// An ink-circle action button beside the destination pill (optionally badged
/// with an active count) — used for the nearby and filter actions.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String? tooltip;
  final VoidCallback onTap;
  const _CircleButton({
    required this.icon,
    this.count = 0,
    this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
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
                icon,
                color: isDark ? AppColors.darkBg : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _CategoryStrip extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _CategoryStrip({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    // A–Z for travellers (the catalog order stays for admin / add-spot).
    final categories = [...context.watch<CategoryStore>().enabled]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
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
