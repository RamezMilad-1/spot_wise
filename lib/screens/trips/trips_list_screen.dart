import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/utils/formatters.dart';
import '../../models/trip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/app_menu_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/max_width.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/state_views.dart';
import '../shell/home_shell.dart';

class TripsListScreen extends StatelessWidget {
  const TripsListScreen({super.key});

  Future<void> _newTrip(BuildContext context) async {
    if (await ensureLoggedIn(context) && context.mounted) {
      if (context.mounted) Navigator.pushNamed(context, AppRoutes.createTrip);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tripsP = context.watch<TripsProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: const Text('My trips'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newTrip(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New trip'),
      ),
      body: !auth.isLoggedIn ? _guestState(context) : _body(context, tripsP),
    );
  }

  Widget _guestState(BuildContext context) => EmptyView(
    icon: Icons.luggage_outlined,
    title: 'Plan your first trip',
    message:
        'Sign in to build day-by-day itineraries and keep them in one place.',
    action: FilledButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
      icon: const Icon(Icons.login_rounded),
      label: const Text('Sign in'),
    ),
  );

  Widget _body(BuildContext context, TripsProvider tripsP) {
    if (tripsP.loading && tripsP.isEmpty) return const LoadingView();
    if (tripsP.isEmpty) {
      return EmptyView(
        icon: Icons.luggage_outlined,
        title: 'No trips yet',
        message:
            'Plan a trip yourself, or let SpotWise AI build a day-by-day itinerary.',
        action: FilledButton.icon(
          onPressed: () => context.read<HomeTab>().go(2),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Plan with AI'),
        ),
      );
    }

    final upcoming = tripsP.upcoming;
    final completed = tripsP.completed;

    return MaxWidthBox(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
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
      ),
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
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.tripDetails,
            arguments: trip,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  NetworkPhoto(
                    trip.coverPhoto,
                    width: double.infinity,
                    height: 156,
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: AppColors.cardScrim),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.md,
                    child: Text(
                      trip.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                  if (trip.aiGenerated)
                    const Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Pill(
                        label: 'AI',
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.ink,
                        glass: true,
                      ),
                    ),
                  if (trip.completed)
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: text.bodySmall?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.dateRange(trip.startDate, trip.endDate),
                      style: text.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${trip.dayCount} days · ${trip.stopCount} stops',
                      style: text.bodySmall,
                    ),
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
