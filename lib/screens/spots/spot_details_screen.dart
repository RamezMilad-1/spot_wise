import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/spot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spot_details_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/badges.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/section_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final detailsP = context.watch<SpotDetailsProvider>();
    final auth = context.watch<AuthProvider>();
    final spot = detailsP.spot;
    final text = Theme.of(context).textTheme;
    final saved = auth.isSaved(spot.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              IconButton(
                icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: AppColors.coral),
                onPressed: auth.isLoggedIn ? () => auth.toggleSave(spot.id) : null,
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _report(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoCarousel(photos: spot.photos),
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
                      Expanded(child: Text(spot.name, style: text.headlineSmall)),
                      const SizedBox(width: AppSpacing.sm),
                      RatingStars(spot.rating, size: 18, showValue: true, count: spot.reviewCount),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 18, color: text.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(child: Text(spot.location, style: text.bodyLarge)),
                    ],
                  ),
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
                        const Pill(label: 'Family', icon: Icons.family_restroom_rounded, color: AppColors.teal),
                    ],
                  ),
                  if (spot.bestTimeToVisit.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _InfoRow(icon: Icons.schedule_rounded, label: 'Best time', value: spot.bestTimeToVisit),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(spot.description, style: text.bodyLarge?.copyWith(height: 1.5)),
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
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.outline(
                    'Open in Google Maps',
                    icon: Icons.directions_rounded,
                    onPressed: () => _openInMaps(spot),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Reviews',
              subtitle: spot.reviewCount == 0 ? 'Be the first to review' : '${spot.reviewCount} traveller reviews',
              actionLabel: 'Write',
              onAction: () => _writeReview(context),
            ),
          ),
          _ReviewsSliver(detailsP: detailsP),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        saved: saved,
        canSave: auth.isLoggedIn,
        onSave: () => auth.toggleSave(spot.id),
        onAddToTrip: () => _addToTrip(context, spot),
      ),
    );
  }

  Future<void> _writeReview(BuildContext context) async {
    final detailsP = context.read<SpotDetailsProvider>();
    final result = await Navigator.pushNamed(context, AppRoutes.addReview, arguments: detailsP.spot);
    if (result is (double, String, List<String>)) {
      await detailsP.addReview(rating: result.$1, comment: result.$2, photos: result.$3);
      if (context.mounted) AppSnackbar.success(context, 'Thanks for your review!');
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
          decoration: const InputDecoration(hintText: 'What\'s wrong with this listing?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      await detailsP.report(reason);
      if (context.mounted) AppSnackbar.success(context, 'Report submitted. Our admins will take a look.');
    }
  }

  Future<void> _addToTrip(BuildContext context, Spot spot) async {
    final tripsP = context.read<TripsProvider>();
    await tripsP.load();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Add to a trip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            if (tripsP.trips.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('You have no trips yet — create one to start planning.'),
              ),
            for (final trip in tripsP.trips)
              ListTile(
                leading: const Icon(Icons.luggage_rounded),
                title: Text(trip.destination),
                subtitle: Text('${trip.dayCount} days · ${trip.stopCount} stops'),
                onTap: () async {
                  await tripsP.addSpotToTrip(trip, spot);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) AppSnackbar.success(context, 'Added to ${trip.destination}');
                },
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                'Create a new trip',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.createTrip, arguments: spot);
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
        const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.photoScrim)),
        if (photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index ? Colors.white : Colors.white54,
                    ),
                  ),
              ],
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
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  userAgentPackageName: AppConfig.osmUserAgent,
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: spot.latLng,
                    width: 44,
                    height: 44,
                    child: SpotMarker(categoryId: spot.categoryId, selected: true),
                  ),
                ]),
              ],
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onOpen),
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
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: Theme.of(context).textTheme.titleSmall),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
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
        child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator())),
      );
    }
    if (detailsP.reviews.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Text('No reviews yet. Share your experience!',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return SliverList.builder(
      itemCount: detailsP.reviews.length,
      itemBuilder: (context, i) {
        final r = detailsP.reviews[i];
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(photoUrl: r.userPhoto, initials: _initials(r.userName), radius: 18),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.userName, style: Theme.of(context).textTheme.titleSmall),
                        Text(Formatters.relative(r.createdAt),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  RatingStars(r.rating, size: 14),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(r.comment, style: Theme.of(context).textTheme.bodyMedium),
              const Divider(height: AppSpacing.xl),
            ],
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
  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback onAddToTrip;

  const _BottomBar({
    required this.saved,
    required this.canSave,
    required this.onSave,
    required this.onAddToTrip,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: AppButton.outline(
                saved ? 'Saved' : 'Save',
                icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                onPressed: canSave ? onSave : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton('Add to trip', icon: Icons.add_location_alt_outlined, onPressed: onAddToTrip),
            ),
          ],
        ),
      ),
    );
  }
}
