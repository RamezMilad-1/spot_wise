import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/enums.dart';
import '../../models/spot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/badges.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/state_views.dart';

/// Lists every spot the signed-in user has submitted, across all moderation
/// statuses, so they can track and edit their own contributions.
class MySpotsScreen extends StatefulWidget {
  const MySpotsScreen({super.key});

  @override
  State<MySpotsScreen> createState() => _MySpotsScreenState();
}

class _MySpotsScreenState extends State<MySpotsScreen> {
  late Future<List<Spot>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Spot>> _load() {
    final uid = context.read<AuthProvider>().user?.id;
    if (uid == null) return Future.value(const []);
    return context.read<SpotsProvider>().mySpots(uid);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spots I posted')),
      body: FutureBuilder<List<Spot>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final spots = snap.data ?? const <Spot>[];
          if (spots.isEmpty) {
            return const EmptyView(
              icon: Icons.add_location_alt_outlined,
              title: 'No posts yet',
              message:
                  'Spots you submit will show here with their review status.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: spots.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) =>
                  _MySpotCard(spot: spots[i], onChanged: _refresh),
            ),
          );
        },
      ),
    );
  }
}

class _MySpotCard extends StatelessWidget {
  final Spot spot;
  final Future<void> Function() onChanged;
  const _MySpotCard({required this.spot, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.spotDetails,
          arguments: spot,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkPhoto(spot.coverPhoto, width: double.infinity, height: 140),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(spot.name, style: text.titleMedium)),
                      StatusBadge(spot.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(spot.location, style: text.bodySmall),
                  if (spot.status == SpotStatus.rejected &&
                      (spot.rejectionReason?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Reason: ${spot.rejectionReason}',
                      style: text.bodySmall?.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.spotDetails,
                          arguments: spot,
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('View'),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.editSpot,
                            arguments: spot,
                          );
                          await onChanged();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
