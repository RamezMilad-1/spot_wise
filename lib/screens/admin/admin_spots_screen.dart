import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/categories.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/country_flags.dart';
import '../../models/enums.dart';
import '../../models/spot.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/badges.dart';
import '../../widgets/choice_chip_row.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_photo.dart';
import '../../widgets/state_views.dart';

enum _SpotSort {
  newest('Newest first'),
  oldest('Oldest first'),
  nameAZ('Name A–Z'),
  topRated('Top rated');

  final String label;
  const _SpotSort(this.label);
}

/// Full spot management for admins: search every spot (any status), filter by
/// status / category / country / flags, sort, edit, delete, and toggle
/// verified / featured.
class AdminSpotsScreen extends StatefulWidget {
  const AdminSpotsScreen({super.key});

  @override
  State<AdminSpotsScreen> createState() => _AdminSpotsScreenState();
}

class _AdminSpotsScreenState extends State<AdminSpotsScreen> {
  String _query = '';
  SpotStatus? _status;
  String? _categoryId;
  String? _country;
  bool _featuredOnly = false;
  bool _verifiedOnly = false;
  _SpotSort _sort = _SpotSort.newest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminProvider>().loadAllSpots(),
    );
  }

  bool get _hasFilters =>
      _status != null ||
      _categoryId != null ||
      _country != null ||
      _featuredOnly ||
      _verifiedOnly;

  void _clearFilters() => setState(() {
    _status = null;
    _categoryId = null;
    _country = null;
    _featuredOnly = false;
    _verifiedOnly = false;
  });

  List<Spot> _apply(List<Spot> all) {
    final q = _query.trim().toLowerCase();
    final spots = all.where((s) {
      if (q.isNotEmpty &&
          !'${s.name} ${s.city} ${s.country}'.toLowerCase().contains(q)) {
        return false;
      }
      if (_status != null && s.status != _status) return false;
      if (_categoryId != null && s.categoryId != _categoryId) return false;
      // Case-insensitive: user-submitted spots may type "germany".
      if (_country != null &&
          s.country.trim().toLowerCase() != _country!.trim().toLowerCase()) {
        return false;
      }
      if (_featuredOnly && !s.featured) return false;
      if (_verifiedOnly && !s.verified) return false;
      return true;
    }).toList();
    switch (_sort) {
      case _SpotSort.newest:
        spots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SpotSort.oldest:
        spots.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SpotSort.nameAZ:
        spots.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _SpotSort.topRated:
        spots.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return spots;
  }

  Future<void> _delete(Spot spot) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete “${spot.name}”?',
      message: 'This permanently removes the spot for everyone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<AdminProvider>().deleteSpot(spot);
    if (mounted) AppSnackbar.show(context, 'Spot deleted.');
  }

  Future<void> _edit(Spot spot) async {
    await Navigator.pushNamed(context, AppRoutes.editSpot, arguments: spot);
    if (mounted) context.read<AdminProvider>().loadAllSpots();
  }

  @override
  Widget build(BuildContext context) {
    final adminP = context.watch<AdminProvider>();
    final all = adminP.allSpots;
    final spots = _apply(all);

    int byStatus(SpotStatus s) => all.where((e) => e.status == s).length;

    // Only offer categories/countries that actually exist in the data.
    final categoryIds = {for (final s in all) s.categoryId}.toList()
      ..sort((a, b) => Categories.labelFor(a).compareTo(Categories.labelFor(b)));
    // Deduped case-insensitively, keeping the most common spelling.
    final variantCounts = <String, Map<String, int>>{};
    for (final s in all) {
      final name = s.country.trim();
      if (name.isEmpty) continue;
      final v = variantCounts.putIfAbsent(name.toLowerCase(), () => {});
      v[name] = (v[name] ?? 0) + 1;
    }
    final countries = [
      for (final v in variantCounts.values)
        (v.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key,
    ]..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage spots')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search by name, city or country',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          ChoiceChipRow<SpotStatus?>(
            selected: _status,
            onSelected: (v) => setState(() => _status = v),
            options: [
              ChipOption(null, 'All', count: all.length),
              for (final s in SpotStatus.values)
                ChipOption(s, s.label, count: byStatus(s), icon: s.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _MenuChip<String?>(
                  icon: Icons.category_outlined,
                  label: _categoryId == null
                      ? 'Category'
                      : Categories.labelFor(_categoryId!),
                  active: _categoryId != null,
                  onSelected: (v) => setState(() => _categoryId = v),
                  items: [
                    const _MenuChipItem(null, 'All categories'),
                    for (final id in categoryIds)
                      _MenuChipItem(
                        id,
                        Categories.labelFor(id),
                        icon: Categories.iconFor(id),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                _MenuChip<String?>(
                  icon: Icons.public_rounded,
                  label: _country == null
                      ? 'Country'
                      : '${countryFlag(_country!)} $_country',
                  active: _country != null,
                  onSelected: (v) => setState(() => _country = v),
                  items: [
                    const _MenuChipItem(null, 'All countries'),
                    for (final c in countries)
                      _MenuChipItem(c, '${countryFlag(c)} $c'),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  avatar: Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: _featuredOnly ? null : AppColors.amber,
                  ),
                  label: const Text('Featured'),
                  selected: _featuredOnly,
                  showCheckmark: false,
                  onSelected: (v) => setState(() => _featuredOnly = v),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  avatar: Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: _verifiedOnly ? null : AppColors.teal,
                  ),
                  label: const Text('Verified'),
                  selected: _verifiedOnly,
                  showCheckmark: false,
                  onSelected: (v) => setState(() => _verifiedOnly = v),
                ),
                const SizedBox(width: AppSpacing.sm),
                _MenuChip<_SpotSort>(
                  icon: Icons.swap_vert_rounded,
                  label: _sort.label,
                  active: _sort != _SpotSort.newest,
                  onSelected: (v) => setState(() => _sort = v),
                  items: [
                    for (final s in _SpotSort.values) _MenuChipItem(s, s.label),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Text(
                  '${spots.length} of ${all.length} spots',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (_hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: adminP.loadingAll && all.isEmpty
                ? const LoadingView()
                : spots.isEmpty
                ? const EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No spots',
                    message: 'Nothing matches your search or filters.',
                  )
                : RefreshIndicator(
                    onRefresh: () => adminP.loadAllSpots(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: spots.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) => _AdminSpotCard(
                        spot: spots[i],
                        onEdit: () => _edit(spots[i]),
                        onDelete: () => _delete(spots[i]),
                        onToggleFeatured: () => context
                            .read<AdminProvider>()
                            .toggleFeatured(spots[i]),
                        onToggleVerified: () => context
                            .read<AdminProvider>()
                            .toggleVerified(spots[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MenuChipItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  const _MenuChipItem(this.value, this.label, {this.icon});
}

/// A chip that opens a popup menu — compact dropdown filter for the admin
/// toolbars. Fills with ink while a non-default value is active.
class _MenuChip<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final List<_MenuChipItem<T>> items;
  final ValueChanged<T> onSelected;

  const _MenuChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = active
        ? (isDark ? AppColors.darkInk : AppColors.ink)
        : scheme.surfaceContainerHighest;
    final fg = active
        ? (isDark ? AppColors.darkBg : Colors.white)
        : scheme.onSurface;

    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(item.label),
              ],
            ),
          ),
      ],
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.pill),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? fg : scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: fg),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: fg),
          ],
        ),
      ),
    );
  }
}

class _AdminSpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFeatured;
  final VoidCallback onToggleVerified;

  const _AdminSpotCard({
    required this.spot,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFeatured,
    required this.onToggleVerified,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetworkPhoto(
              spot.coverPhoto,
              width: 56,
              height: 56,
              radius: AppRadius.brMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(spot.location, style: text.bodySmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusBadge(spot.status),
                      if (spot.featured)
                        const Pill(
                          label: 'Featured',
                          icon: Icons.star_rounded,
                          color: AppColors.amber,
                        ),
                      if (spot.verified) const VerifiedBadge(),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit();
                  case 'feature':
                    onToggleFeatured();
                  case 'verify':
                    onToggleVerified();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'feature',
                  child: Text(spot.featured ? 'Unfeature' : 'Feature on home'),
                ),
                PopupMenuItem(
                  value: 'verify',
                  child: Text(
                    spot.verified ? 'Remove verified' : 'Mark verified',
                  ),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
