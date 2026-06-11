import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/auth_gate.dart';
import '../../core/utils/formatters.dart';
import '../../models/spot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spot_details_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/feedback.dart';
import '../../widgets/glass_icon_button.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/section_header.dart';
import '../../widgets/spot_card.dart';
import '../../widgets/spot_marker.dart';
import '../../widgets/user_avatar.dart';

class SpotDetailsScreen extends StatelessWidget {
  final Spot spot;
  const SpotDetailsScreen({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SpotDetailsProvider(spot),
      child: const _SpotDetailsView(),
    );
  }
}

class _SpotDetailsView extends StatelessWidget {
  const _SpotDetailsView();

  Future<void> _openInMaps(Spot s) async {
    final uri = Uri.parse('${AppConfig.googleMapsSearch}${s.lat},${s.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleSave(BuildContext context, String spotId) async {
    if (await ensureLoggedIn(context) && context.mounted) {
      context.read<AuthProvider>().toggleSave(spotId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsP = context.watch<SpotDetailsProvider>();
    final auth = context.watch<AuthProvider>();
    final spot = detailsP.spot;
    final text = Theme.of(context).textTheme;
    final saved = auth.isSaved(spot.id);

    return Scaffold(
      // White (surface) canvas so the rounded content panel reads as one
      // editorial sheet under the photo header.
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Align(
              child: GlassIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Align(
                child: SaveHeartPop(
                  saved: saved,
                  child: GlassIconButton(
                    icon: saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: saved ? AppColors.coral : AppColors.ink,
                    tooltip: saved ? 'Saved' : 'Save',
                    onTap: () => _toggleSave(context, spot.id),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Align(
                child: GlassIconButton(
                  icon: Icons.flag_outlined,
                  tooltip: 'Report',
                  onTap: () => _report(context),
                ),
              ),
              if (auth.user?.isAdmin ?? false) ...[
                const SizedBox(width: 6),
                Align(
                  child: GlassIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit spot',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.editSpot,
                      arguments: spot,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.md),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'spot-hero-${spot.id}',
                child: _PhotoCarousel(photos: spot.photos),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(spot.name, style: text.headlineSmall),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RatingStars(
                        spot.rating,
                        size: 18,
                        showValue: true,
                        count: spot.reviewCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: text.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(spot.location, style: text.bodyLarge),
                      ),
                    ],
                  ),
                  if (spot.locationNote.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(
                      icon: Icons.tips_and_updates_outlined,
                      label: 'Finding it',
                      value: spot.locationNote,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      CategoryChip(spot.categoryId),
                      PriceTag(spot.priceRange),
                      if (spot.verified) const VerifiedBadge(),
                      if (spot.hiddenGem) const HiddenGemBadge(),
                      if (spot.familyFriendly)
                        const Pill(
                          label: 'Family',
                          icon: Icons.family_restroom_rounded,
                          color: AppColors.teal,
                        ),
                    ],
                  ),
                  if (spot.bestTimeToVisit.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      label: 'Best time',
                      value: spot.bestTimeToVisit,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    spot.description,
                    style: text.bodyLarge?.copyWith(height: 1.5),
                  ),
                  if (spot.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [for (final t in spot.tags) TagChip(t)],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _MiniMap(spot: spot, onOpen: () => _openInMaps(spot)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Reviews',
              subtitle: spot.reviewCount == 0
                  ? 'Be the first to review'
                  : '${spot.reviewCount} traveller reviews',
              actionLabel: 'Write',
              onAction: () => _writeReview(context),
            ),
          ),
          _ReviewsSliver(detailsP: detailsP),
          if (!detailsP.loading && detailsP.reviews.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: AppButton.outline(
                  'Write a review',
                  icon: Icons.rate_review_outlined,
                  onPressed: () => _writeReview(context),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        saved: saved,
        onSave: () => _toggleSave(context, spot.id),
        onAddToTrip: () => _addToTrip(context, spot),
      ),
    );
  }

  Future<void> _writeReview(BuildContext context) async {
    if (!await ensureLoggedIn(context) || !context.mounted) return;
    final detailsP = context.read<SpotDetailsProvider>();
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addReview,
      arguments: detailsP.spot,
    );
    if (result is (double, String, List<String>)) {
      await detailsP.addReview(
        rating: result.$1,
        comment: result.$2,
        photos: result.$3,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'Thanks for your review!');
      }
    }
  }

  Future<void> _report(BuildContext context) async {
    final detailsP = context.read<SpotDetailsProvider>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report this spot'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What\'s wrong with this listing?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      await detailsP.report(reason);
      if (context.mounted) {
        AppSnackbar.success(
          context,
          'Report submitted. Our admins will take a look.',
        );
      }
    }
  }

  Future<void> _addToTrip(BuildContext context, Spot spot) async {
    if (!await ensureLoggedIn(context) || !context.mounted) return;
    final tripsP = context.read<TripsProvider>();
    await tripsP.load();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Add to a trip',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            if (tripsP.trips.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'You have no trips yet — create one to start planning.',
                ),
              ),
            for (final trip in tripsP.trips)
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.luggage_rounded, size: 20),
                ),
                title: Text(trip.destination),
                subtitle: Text(
                  '${trip.dayCount} days · ${trip.stopCount} stops',
                ),
                onTap: () async {
                  await tripsP.addSpotToTrip(trip, spot);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    AppSnackbar.success(
                      context,
                      'Added to ${trip.destination}',
                    );
                  }
                },
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                'Create a new trip',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.createTrip,
                    arguments: spot,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<String> photos;
  const _PhotoCarousel({required this.photos});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos.isEmpty ? [''] : widget.photos;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => NetworkPhoto(photos[i], fit: BoxFit.cover),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.photoScrim),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < photos.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 18 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _index ? Colors.white : Colors.white54,
                    ),
                  ),
              ],
            ),
          ),
        // Rounded lip that curves the content panel up into the photo.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMap extends StatelessWidget {
  final Spot spot;
  final VoidCallback onOpen;
  const _MiniMap({required this.spot, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brLg,
      child: SizedBox(
        height: 170,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: spot.latLng,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  userAgentPackageName: AppConfig.osmUserAgent,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: spot.latLng,
                      width: 44,
                      height: 44,
                      child: SpotMarker(
                        categoryId: spot.categoryId,
                        selected: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onOpen),
              ),
            ),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: GlassIconButton(
                icon: Icons.directions_rounded,
                tooltip: 'Open in Google Maps',
                style: GlassButtonStyle.dark,
                onTap: onOpen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: Theme.of(context).textTheme.titleSmall),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ReviewsSliver extends StatelessWidget {
  final SpotDetailsProvider detailsP;
  const _ReviewsSliver({required this.detailsP});

  @override
  Widget build(BuildContext context) {
    if (detailsP.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (detailsP.reviews.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Text(
            'No reviews yet. Share your experience!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: detailsP.reviews.length,
      itemBuilder: (context, i) {
        final r = detailsP.reviews[i];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: AppRadius.brLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      photoUrl: r.userPhoto,
                      initials: _initials(r.userName),
                      radius: 18,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.userName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            Formatters.relative(r.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    RatingStars(r.rating, size: 14),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(r.comment, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.first.substring(0, 1).toUpperCase();
  }
}

class _BottomBar extends StatelessWidget {
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onAddToTrip;

  const _BottomBar({
    required this.saved,
    required this.onSave,
    required this.onAddToTrip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                // Raw OutlinedButton instead of AppButton.outline so only the
                // heart pops (AppButton has no child slot for the icon).
                child: OutlinedButton(
                  onPressed: onSave,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SaveHeartPop(
                        saved: saved,
                        child: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: saved ? AppColors.coral : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          saved ? 'Saved' : 'Save',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  'Add to trip',
                  icon: Icons.add_location_alt_outlined,
                  onPressed: onAddToTrip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
