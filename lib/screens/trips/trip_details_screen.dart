import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/notification_item.dart';
import '../../models/trip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/spots_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/spot_list_tile.dart';
import '../../widgets/spot_marker.dart';
import '../../widgets/trip_budget_card.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late final TextEditingController _notes = TextEditingController(text: widget.trip.notes);
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _notes.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Trip get _trip =>
      context.read<TripsProvider>().byId(widget.trip.id) ?? widget.trip;

  Future<void> _delete() async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete this trip?',
      message: 'This can\'t be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<TripsProvider>().deleteTrip(widget.trip.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _remind(Trip trip) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    await context.read<NotificationsProvider>().add(NotificationItem(
          id: '',
          userId: user.id,
          title: 'Trip reminder set',
          body: 'We\'ll remind you about your ${trip.destination} trip.',
          type: NotificationType.tripReminder,
          createdAt: DateTime.now(),
        ));
    if (mounted) AppSnackbar.success(context, 'Reminder added to your notifications.');
  }

  void _openStop(TripStop stop) {
    final spot = context.read<SpotsProvider>().byId(stop.spotId);
    if (spot != null) {
      Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot);
    } else {
      _openInMaps(stop.lat, stop.lng);
    }
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final uri = Uri.parse('${AppConfig.googleMapsSearch}$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDayRoute(TripDay day) async {
    if (day.stops.isEmpty) return;
    final path = day.stops.map((s) => '${s.lat},${s.lng}').join('/');
    final uri = Uri.parse('https://www.google.com/maps/dir/$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addStop(Trip trip, int dayNumber) async {
    final spotsP = context.read<SpotsProvider>();
    final used = trip.days.expand((d) => d.stops).map((s) => s.spotId).toSet();
    final candidates = spotsP.spots.where((s) => !used.contains(s.id)).toList()
      ..sort((a, b) {
        final ac = a.city.toLowerCase() == trip.destination.toLowerCase() ? 0 : 1;
        final bc = b.city.toLowerCase() == trip.destination.toLowerCase() ? 0 : 1;
        return ac.compareTo(bc);
      });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Add a spot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => SpotListTile(
                  spot: candidates[i],
                  trailing: const Icon(Icons.add_circle_outline_rounded),
                  onTap: () async {
                    await context.read<TripsProvider>().addSpotToTrip(trip, candidates[i], dayNumber: dayNumber);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripsProvider>().byId(widget.trip.id) ?? widget.trip;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            actions: [
              IconButton(
                tooltip: trip.completed ? 'Mark as not done' : 'Mark complete',
                icon: Icon(trip.completed ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded),
                color: trip.completed ? AppColors.success : null,
                onPressed: () => context.read<TripsProvider>().toggleComplete(trip),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _delete();
                  if (v == 'remind') _remind(trip);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'remind', child: Text('Set reminder')),
                  PopupMenuItem(value: 'delete', child: Text('Delete trip')),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trip.destination, style: const TextStyle(color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(trip.coverPhoto, fit: BoxFit.cover),
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.photoScrim)),
                ],
              ),
            ),
          ),
          SliverList.list(children: [
            _StopsMap(trip: trip),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: text.bodySmall?.color),
                  const SizedBox(width: 6),
                  Text(Formatters.dateRange(trip.startDate, trip.endDate), style: text.bodyMedium),
                  const Spacer(),
                  if (trip.aiGenerated)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.teal),
                    ),
                  Text('${trip.stopCount} stops', style: text.bodySmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: TripBudgetCard(trip: trip),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Trip notes',
                  hintText: 'Flights, hotel, anything to remember…',
                ),
                onChanged: (v) => _debouncer.run(() {
                  context.read<TripsProvider>().updateNotes(_trip, v);
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final day in trip.days)
              _DaySection(
                trip: trip,
                day: day,
                onAddStop: () => _addStop(trip, day.dayNumber),
                onOpenStop: _openStop,
                onOpenRoute: () => _openDayRoute(day),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton.outline(
                'Add a day',
                icon: Icons.add_rounded,
                onPressed: () => context.read<TripsProvider>().addDay(trip),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ]),
        ],
      ),
    );
  }
}

class _StopsMap extends StatelessWidget {
  final Trip trip;
  const _StopsMap({required this.trip});

  @override
  Widget build(BuildContext context) {
    final stops = trip.days.expand((d) => d.stops).toList();
    if (stops.isEmpty) return const SizedBox.shrink();
    final center = trip.latLng ?? stops.first.latLng;

    return SizedBox(
      height: 180,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
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
    );
  }
}

class _DaySection extends StatelessWidget {
  final Trip trip;
  final TripDay day;
  final VoidCallback onAddStop;
  final VoidCallback onOpenRoute;
  final void Function(TripStop) onOpenStop;

  const _DaySection({
    required this.trip,
    required this.day,
    required this.onAddStop,
    required this.onOpenRoute,
    required this.onOpenStop,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tripsP = context.read<TripsProvider>();
    final dayCost = day.stops.fold<double>(0, (s, st) => s + st.estimatedCost);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.tealMist,
                child: Text('${day.dayNumber}',
                    style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.title.isEmpty ? 'Day ${day.dayNumber}' : day.title, style: text.titleMedium),
                    if (day.date != null)
                      Text(
                        '${Formatters.weekday(day.date!)}${dayCost > 0 ? ' · ${Formatters.money(dayCost)}' : ''}',
                        style: text.bodySmall,
                      ),
                  ],
                ),
              ),
              if (day.stops.isNotEmpty)
                IconButton(
                  tooltip: 'Open day in Google Maps',
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  onPressed: onOpenRoute,
                ),
              TextButton.icon(
                onPressed: onAddStop,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (day.stops.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('No stops yet — add one.', style: text.bodySmall),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: true,
              onReorder: (oldI, newI) => tripsP.reorderStops(trip, day.dayNumber, oldI, newI),
              children: [
                for (var i = 0; i < day.stops.length; i++)
                  _StopTile(
                    key: ValueKey('${day.dayNumber}-${day.stops[i].spotId}-$i'),
                    stop: day.stops[i],
                    onRemove: () => tripsP.removeStop(trip, day.dayNumber, i),
                    onTap: () => onOpenStop(day.stops[i]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  final TripStop stop;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  const _StopTile({super.key, required this.stop, required this.onRemove, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sub = [
      stop.dayPart.label,
      if (stop.suggestedTime.isNotEmpty) stop.suggestedTime,
      stop.estimatedCost > 0 ? Formatters.money(stop.estimatedCost) : 'Free',
      if (stop.durationMinutes > 0) Formatters.duration(stop.durationMinutes),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              children: [
                NetworkPhoto(stop.photo, width: 48, height: 48, radius: AppRadius.brSm),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(stop.dayPart.icon, size: 13, color: AppColors.teal),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(sub,
                                style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
