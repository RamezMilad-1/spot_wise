import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/trip.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/state_views.dart';
import '../shell/home_shell.dart';

class TripsListScreen extends StatelessWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripsP = context.watch<TripsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My trips')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createTrip),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New trip'),
      ),
      body: _body(context, tripsP),
    );
  }

  Widget _body(BuildContext context, TripsProvider tripsP) {
    if (tripsP.loading && tripsP.isEmpty) return const LoadingView();
    if (tripsP.isEmpty) {
      return EmptyView(
        icon: Icons.luggage_outlined,
        title: 'No trips yet',
        message: 'Plan a trip yourself, or let SpotWise AI build a day-by-day itinerary.',
        action: FilledButton.icon(
          onPressed: () => context.read<HomeTab>().go(2),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Plan with AI'),
        ),
      );
    }

    final upcoming = tripsP.upcoming;
    final completed = tripsP.completed;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (upcoming.isNotEmpty) ...[
          Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final t in upcoming) _TripCard(trip: t),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Completed', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final t in completed) _TripCard(trip: t),
        ],
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.tripDetails, arguments: trip),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  NetworkPhoto(trip.coverPhoto, width: double.infinity, height: 130),
                  const Positioned.fill(
                    child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.photoScrim)),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Text(
                      trip.destination,
                      style: text.headlineSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                  if (trip.aiGenerated)
                    const Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Chip(
                        avatar: Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                        label: Text('AI', style: TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.teal,
                      ),
                    ),
                  if (trip.completed)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: text.bodySmall?.color),
                    const SizedBox(width: 6),
                    Text(Formatters.dateRange(trip.startDate, trip.endDate), style: text.bodyMedium),
                    const Spacer(),
                    Text('${trip.dayCount} days · ${trip.stopCount} stops', style: text.bodySmall),
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
