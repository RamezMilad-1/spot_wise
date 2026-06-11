import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/country_flags.dart';
import '../models/spot.dart';
import 'app_text_field.dart';
import 'spot_list_tile.dart';

/// What the destination sheet was closed with: a destination (`country` /
/// `city`, both empty = "anywhere") or a single [spot] found via search.
class DestinationPick {
  final String country;
  final String city;
  final Spot? spot;

  const DestinationPick({this.country = '', this.city = '', this.spot});
}

/// Two-step destination picker: choose a country, then (optionally) drill into
/// one of its cities. Both lists come from the live spot data, so only places
/// that actually have spots are offered. The first step also has a free-text
/// search across countries, cities and spot names.
///
/// Returns a [DestinationPick], or null if dismissed.
Future<DestinationPick?> showDestinationPicker(
  BuildContext context, {
  required List<MapEntry<String, int>> countries,
  required List<MapEntry<String, int>> Function(String country) citiesFor,
  required List<Spot> spots,
  String country = '',
  String city = '',
  bool startOnCities = false,
}) {
  return showModalBottomSheet<DestinationPick>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DestinationSheet(
      countries: countries,
      citiesFor: citiesFor,
      spots: spots,
      initialCountry: country,
      initialCity: city,
      startOnCities: startOnCities && country.isNotEmpty,
    ),
  );
}

class _DestinationSheet extends StatefulWidget {
  final List<MapEntry<String, int>> countries;
  final List<MapEntry<String, int>> Function(String country) citiesFor;
  final List<Spot> spots;
  final String initialCountry;
  final String initialCity;
  final bool startOnCities;

  const _DestinationSheet({
    required this.countries,
    required this.citiesFor,
    required this.spots,
    required this.initialCountry,
    required this.initialCity,
    required this.startOnCities,
  });

  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
  /// Country whose cities are being browsed; empty = country step.
  late String _browsing = widget.startOnCities ? widget.initialCountry : '';
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool get _onCities => _browsing.isNotEmpty;
  bool get _searching => _query.trim().length >= 2;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _pickCountry(String country) {
    if (country.isEmpty) {
      Navigator.pop(context, const DestinationPick());
      return;
    }
    if (widget.citiesFor(country).isEmpty) {
      // Nothing to drill into — select the whole country directly.
      Navigator.pop(context, DestinationPick(country: country));
      return;
    }
    setState(() => _browsing = country);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        // Keep the lists above the keyboard while searching.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _onCities ? _cityStep(context) : _countryStep(context),
          ),
        ),
      ),
    );
  }

  // ── Step 1: countries (+ free-text search) ───────────────────────────────
  Widget _countryStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final selected = widget.initialCountry;
    return Column(
      key: const ValueKey('countries'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xs,
          ),
          child: Text('Where to?', style: text.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Pick a country, then narrow down to a city.',
            style: text.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: AppSearchField(
            controller: _searchCtrl,
            hint: 'Search spots or places',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: _searching
                ? _searchResults(context)
                : [
                    _DestinationTile(
                      emoji: '🌍',
                      label: 'All countries',
                      selected: selected.isEmpty,
                      onTap: () => _pickCountry(''),
                    ),
                    for (final e in widget.countries)
                      _DestinationTile(
                        emoji: countryFlag(e.key),
                        label: e.key,
                        count: e.value,
                        selected: e.key == selected,
                        showChevron: true,
                        onTap: () => _pickCountry(e.key),
                      ),
                  ],
          ),
        ),
      ],
    );
  }

  /// Search across countries, cities and spot names/tags.
  List<Widget> _searchResults(BuildContext context) {
    final q = _query.trim().toLowerCase();

    final countries = widget.countries
        .where((e) => e.key.toLowerCase().contains(q))
        .toList();

    // Unique city → country pairs from the data (case-insensitive).
    final cityPairs = <String, (String, String, int)>{};
    for (final s in widget.spots) {
      final city = s.city.trim();
      if (city.isEmpty || !city.toLowerCase().contains(q)) continue;
      final key = '${city.toLowerCase()}|${s.country.trim().toLowerCase()}';
      final prev = cityPairs[key];
      cityPairs[key] = (
        prev?.$1 ?? city,
        prev?.$2 ?? s.country.trim(),
        (prev?.$3 ?? 0) + 1,
      );
    }
    final cities = cityPairs.values.toList()
      ..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));

    final spots = widget.spots
        .where(
          (s) => '${s.name} ${s.city} ${s.tags.join(' ')}'
              .toLowerCase()
              .contains(q),
        )
        .take(8)
        .toList();

    Widget label(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Text(t, style: Theme.of(context).textTheme.labelLarge),
    );

    return [
      if (countries.isEmpty && cities.isEmpty && spots.isEmpty)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No spots or places match “${_query.trim()}”.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      if (countries.isNotEmpty) ...[
        label('Countries'),
        for (final e in countries)
          _DestinationTile(
            emoji: countryFlag(e.key),
            label: e.key,
            count: e.value,
            selected: false,
            showChevron: true,
            onTap: () => _pickCountry(e.key),
          ),
      ],
      if (cities.isNotEmpty) ...[
        label('Cities'),
        for (final c in cities)
          _DestinationTile(
            icon: Icons.location_city_rounded,
            label: '${c.$1}, ${c.$2}',
            count: c.$3,
            selected: false,
            onTap: () => Navigator.pop(
              context,
              DestinationPick(country: c.$2, city: c.$1),
            ),
          ),
      ],
      if (spots.isNotEmpty) ...[
        label('Spots'),
        for (final s in spots)
          SpotListTile(
            spot: s,
            onTap: () => Navigator.pop(context, DestinationPick(spot: s)),
          ),
      ],
    ];
  }

  // ── Step 2: cities of the chosen country ─────────────────────────────────
  Widget _cityStep(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cities = widget.citiesFor(_browsing);
    final sameCountry = _browsing == widget.initialCountry;
    return Column(
      key: ValueKey('cities-$_browsing'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              IconButton(
                tooltip: 'All countries',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _browsing = ''),
              ),
              Text(countryFlag(_browsing), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _browsing,
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text('Choose a city, or take it all in.', style: text.bodySmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              _DestinationTile(
                emoji: countryFlag(_browsing),
                label: 'Entire $_browsing',
                selected: sameCountry && widget.initialCity.isEmpty,
                onTap: () =>
                    Navigator.pop(context, DestinationPick(country: _browsing)),
              ),
              for (final e in cities)
                _DestinationTile(
                  icon: Icons.location_city_rounded,
                  label: e.key,
                  count: e.value,
                  selected: sameCountry && e.key == widget.initialCity,
                  onTap: () => Navigator.pop(
                    context,
                    DestinationPick(country: _browsing, city: e.key),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One row in the destination sheet: flag/icon, name, spot count and a
/// check (current selection) or chevron (drills into cities).
class _DestinationTile extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String label;
  final int? count;
  final bool selected;
  final bool showChevron;
  final VoidCallback onTap;

  const _DestinationTile({
    this.emoji,
    this.icon,
    required this.label,
    this.count,
    required this.selected,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected
          ? scheme.surfaceContainerHighest
          : Colors.transparent,
      borderRadius: AppRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 20))
                    : Icon(icon, size: 20, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    '$count ${count == 1 ? 'spot' : 'spots'}',
                    style: text.bodySmall,
                  ),
                ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: scheme.onSurface,
                  ),
                )
              else if (showChevron)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
