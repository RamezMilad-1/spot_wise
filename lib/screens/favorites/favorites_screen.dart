import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/spot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/spot_card.dart';
import '../../widgets/state_views.dart';

/// Saved spots — kept offline in Hive via the user record. Accessed from the
/// profile.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final spotsP = context.watch<SpotsProvider>();
    final savedIds = auth.user?.savedSpotIds ?? const [];
    final saved = savedIds.map(spotsP.byId).whereType<Spot>().toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved spots')),
      body: saved.isEmpty
          ? const EmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'No saved spots yet',
              message: 'Tap the heart on any spot to keep it here for later — available offline.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: saved.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (_, i) {
                final spot = saved[i];
                return SpotCard(
                  spot: spot,
                  isSaved: true,
                  onToggleSave: () => auth.toggleSave(spot.id),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: spot),
                );
              },
            ),
    );
  }
}
