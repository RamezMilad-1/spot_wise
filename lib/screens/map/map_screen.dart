import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/spot.dart';
import '../../providers/map_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/app_menu_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/spot_list_tile.dart';
import '../../widgets/spot_marker.dart';
import 'filter_sheet.dart';

/// Map-first discovery: OpenStreetMap tiles, clustered category markers, city
/// search and a filter sheet. No API key required.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  int _lastTick = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncCamera(MapProvider mapP) {
    if (mapP.moveTick != _lastTick) {
      _lastTick = mapP.moveTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.move(mapP.center, mapP.zoom);
      });
    }
  }

  Future<void> _openSearch() async {
    await Navigator.pushNamed(context, AppRoutes.search);
  }

  Future<void> _locate(MapProvider mapP) async {
    final found = await mapP.locateMe();
    if (!mounted || found) return;
    AppSnackbar.show(
      context,
      'Couldn\'t find your location — check that location is on and permission '
      'is granted.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotsP = context.watch<SpotsProvider>();
    final mapP = context.watch<MapProvider>();
    _syncCamera(mapP);

    final visible = mapP.visible(spotsP.spots);
    final selected = mapP.selectedSpotId == null
        ? null
        : spotsP.byId(mapP.selectedSpotId!);

    final markers = [
      for (final s in visible)
        Marker(
          point: s.latLng,
          width: 48,
          height: 48,
          child: SpotMarker(
            categoryId: s.categoryId,
            selected: s.id == mapP.selectedSpotId,
            onTap: () {
              mapP.select(s.id);
              _controller.move(s.latLng, _controller.camera.zoom.clamp(13, 18));
            },
          ),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: mapP.center,
              initialZoom: mapP.zoom,
              minZoom: 2,
              maxZoom: 18,
              onTap: (_, _) => mapP.select(null),
            ),
            children: [
              TileLayer(
                urlTemplate: Theme.of(context).brightness == Brightness.dark
                    ? AppConfig.osmTileUrlDark
                    : AppConfig.osmTileUrl,
                userAgentPackageName: AppConfig.osmUserAgent,
                maxZoom: 19,
              ),
              if (mapP.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapP.userLocation!,
                      width: 22,
                      height: 22,
                      child: const _UserDot(),
                    ),
                  ],
                ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 48,
                  size: const Size(44, 44),
                  padding: const EdgeInsets.all(50),
                  markers: markers,
                  builder: (context, clustered) =>
                      ClusterMarker(clustered.length),
                ),
              ),
            ],
          ),
          // CARTO requires visible attribution wherever its tiles are shown.
          Positioned(
            left: AppSpacing.md,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xs,
            child: IgnorePointer(
              child: Text(
                '© OpenStreetMap © CARTO',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _TopBar(
                activeFilters: mapP.filter.activeCount,
                onSearch: _openSearch,
                onFilter: () => _openFilters(context, mapP),
              ),
            ),
          ),
          if (visible.isEmpty)
            const Positioned(
              top: 96,
              left: 0,
              right: 0,
              child: Center(child: _EmptyPill()),
            ),
          if (selected != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              // Clear the floating dock (injected into bottom MediaQuery padding).
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
              child: _SelectedCard(
                spot: selected,
                onClose: () => mapP.select(null),
              ),
            ),
          // Locate-me button. Positioned (not a Scaffold FAB) so it clears the
          // floating dock instead of colliding with it.
          if (selected == null)
            Positioned(
              right: AppSpacing.md,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
              child: FloatingActionButton(
                heroTag: 'locate',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                tooltip: 'My location',
                onPressed: mapP.locating ? null : () => _locate(mapP),
                child: mapP.locating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, MapProvider mapP) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        initial: mapP.filter,
        hasLocation: mapP.userLocation != null,
        onApply: mapP.setFilter,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int activeFilters;
  final VoidCallback onSearch;
  final VoidCallback onFilter;

  const _TopBar({
    required this.activeFilters,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _TopBarPill(
          onTap: () => shellScaffoldKey.currentState?.openDrawer(),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(Icons.menu_rounded, color: scheme.onSurface),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _TopBarPill(
            onTap: onSearch,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
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
        const SizedBox(width: AppSpacing.sm),
        _TopBarPill(
          onTap: onFilter,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.tune_rounded, color: scheme.onSurface),
                if (activeFilters > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$activeFilters',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft-shadowed pill container for the map's floating top controls.
class _TopBarPill extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _TopBarPill({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadius.pill));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, borderRadius: radius, child: child),
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback onClose;
  const _SelectedCard({required this.spot, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SpotListTile(
                    spot: spot,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.spotDetails,
                      arguments: spot,
                    ),
                    trailing: const SizedBox.shrink(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPill extends StatelessWidget {
  const _EmptyPill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      elevation: 2,
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text('No spots match your filters'),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.info,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
