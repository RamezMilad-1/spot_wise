import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/trip.dart';
import '../../providers/ai_planner_provider.dart';
import '../../providers/spots_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/spot_marker.dart';
import '../../widgets/trip_budget_card.dart';

class ItineraryResultScreen extends StatefulWidget {
  final Trip trip;
  const ItineraryResultScreen({super.key, required this.trip});

  @override
  State<ItineraryResultScreen> createState() => _ItineraryResultScreenState();
}

class _ItineraryResultScreenState extends State<ItineraryResultScreen> {
  /// Local copy so AI stop swaps update this screen in place.
  late Trip _trip = widget.trip;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final tripsP = context.read<TripsProvider>();
    final id = await tripsP.createTrip(_trip);
    if (!mounted) return;
    final created = tripsP.byId(id) ?? _trip;
    AppSnackbar.success(context, 'Saved to your trips');
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.tripDetails,
      arguments: created,
    );
  }

  /// Asks the AI for a replacement for one stop; the rest of the day re-flows
  /// around whatever it picks.
  Future<void> _swap(int dayIndex, int stopIndex) async {
    final aiP = context.read<AiPlannerProvider>();
    final spots = context.read<SpotsProvider>().spots;
    final before = _trip.days[dayIndex].stops[stopIndex];
    final updated = await aiP.replaceStop(
      trip: _trip,
      dayIndex: dayIndex,
      stopIndex: stopIndex,
      spots: spots,
    );
    if (!mounted) return;
    if (updated == null) {
      AppSnackbar.error(context, aiP.error ?? 'Couldn\'t swap that stop.');
      return;
    }
    final after = updated.days[dayIndex].stops[stopIndex];
    if (after.spotId == before.spotId) {
      AppSnackbar.show(context, 'No other nearby spots to swap in.');
      return;
    }
    setState(() => _trip = updated);
    AppSnackbar.success(context, 'Swapped in “${after.name}”.');
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final swapping = context.watch<AiPlannerProvider>().swapping;
    final text = Theme.of(context).textTheme;
    final stops = trip.days.expand((d) => d.stops).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your itinerary')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(trip.destination, style: text.displaySmall),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${Formatters.dateRange(trip.startDate, trip.endDate)} · ${trip.dayCount} days · ${trip.stopCount} stops',
                  style: text.bodyMedium,
                ),
                if (trip.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(trip.notes, style: text.bodySmall),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TripBudgetCard(trip: trip),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ClipRRect(
                borderRadius: AppRadius.brLg,
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: trip.latLng ?? stops.first.latLng,
                      initialZoom: 11.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConfig.osmTileUrl,
                        userAgentPackageName: AppConfig.osmUserAgent,
                      ),
                      MarkerLayer(
                        markers: [
                          for (final s in stops)
                            Marker(
                              point: LatLng(s.lat, s.lng),
                              width: 40,
                              height: 40,
                              child: SpotMarker(categoryId: s.categoryId),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          for (final (i, day) in trip.days.indexed)
            _DayCard(
              day: day,
              dayIndex: i,
              swapping: swapping,
              onSwap: _swap,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  'Tweak brief',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  'Save trip',
                  icon: Icons.bookmark_added_rounded,
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final TripDay day;
  final int dayIndex;
  final (int, int)? swapping;
  final void Function(int dayIndex, int stopIndex) onSwap;

  const _DayCard({
    required this.day,
    required this.dayIndex,
    required this.swapping,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${day.dayNumber}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      day.title.isEmpty ? 'Day ${day.dayNumber}' : day.title,
                      style: text.titleMedium,
                    ),
                  ),
                ],
              ),
              if (day.summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(day.summary, style: text.bodySmall),
              ],
              const SizedBox(height: AppSpacing.md),
              for (final (i, stop) in day.stops.indexed)
                _StopRow(
                  stop: stop,
                  busy: swapping == (dayIndex, i),
                  swapEnabled: swapping == null,
                  onSwap: () => onSwap(dayIndex, i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final TripStop stop;
  final bool busy;
  final bool swapEnabled;
  final VoidCallback onSwap;

  const _StopRow({
    required this.stop,
    required this.busy,
    required this.swapEnabled,
    required this.onSwap,
  });

  void _open(BuildContext context) {
    final spot = context.read<SpotsProvider>().byId(stop.spotId);
    if (spot != null) {
      Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final meta = [
      if (stop.estimatedCost > 0) Formatters.money(stop.estimatedCost),
      if (stop.estimatedCost == 0) 'Free',
      if (stop.durationMinutes > 0) Formatters.duration(stop.durationMinutes),
    ].join(' · ');

    return InkWell(
      onTap: () => _open(context),
      borderRadius: AppRadius.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  stop.dayPart.icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                if (stop.suggestedTime.isNotEmpty)
                  Text(stop.suggestedTime, style: text.bodySmall),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            NetworkPhoto(
              stop.photo,
              width: 52,
              height: 52,
              radius: AppRadius.brMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.name, style: text.titleSmall),
                  if (stop.note.isNotEmpty)
                    Text(
                      stop.note,
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: text.labelSmall?.copyWith(color: AppColors.teal),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Swap with AI',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.autorenew_rounded, size: 20),
                onPressed: swapEnabled ? onSwap : null,
              ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
