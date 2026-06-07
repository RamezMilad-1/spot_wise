import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../models/spot.dart';
import '../../providers/map_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/section_header.dart';
import '../../widgets/spot_list_tile.dart';

/// City/country search (Nominatim) + live filtering of local spots.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    context.read<MapProvider>().clearSearch();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debouncer.run(() {
      if (!mounted) return;
      final t = value.trim();
      if (t.length >= 2) {
        context.read<MapProvider>().search(t);
      } else {
        context.read<MapProvider>().clearSearch();
      }
    });
  }

  void _selectCity(String city) {
    _controller.text = city;
    _onChanged(city);
  }

  @override
  Widget build(BuildContext context) {
    final spotsP = context.watch<SpotsProvider>();
    final mapP = context.watch<MapProvider>();
    final q = _query.trim().toLowerCase();
    final localMatches = q.isEmpty
        ? <Spot>[]
        : spotsP.spots
            .where((s) => '${s.name} ${s.city} ${s.country} ${s.tags.join(' ')}'
                .toLowerCase()
                .contains(q))
            .take(25)
            .toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: AppSearchField(
            controller: _controller,
            hint: 'Search cities or spots',
            autofocus: true,
            onChanged: _onChanged,
            onClear: () => _onChanged(''),
          ),
        ),
      ),
      body: q.isEmpty ? _suggestions(context, spotsP) : _results(context, mapP, localMatches),
    );
  }

  Widget _suggestions(BuildContext context, SpotsProvider spotsP) {
    final cities = spotsP.cities;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Popular destinations', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final city in cities)
              ActionChip(
                avatar: const Icon(Icons.place_outlined, size: 18),
                label: Text(city),
                onPressed: () => _selectCity(city),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Tip: search any city in the world to recenter the map.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _results(BuildContext context, MapProvider mapP, List<Spot> spots) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (mapP.searching) const LinearProgressIndicator(minHeight: 2),
        if (mapP.searchResults.isNotEmpty) ...[
          const SectionHeader(title: 'Places'),
          for (final place in mapP.searchResults)
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: Text(place.name),
              subtitle: Text(
                place.country.isEmpty ? place.displayName : place.country,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.map_outlined),
              onTap: () {
                context.read<MapProvider>().goToPlace(place);
                Navigator.pop(context, 'map');
              },
            ),
        ],
        SectionHeader(title: 'Spots', subtitle: '${spots.length} match'),
        if (spots.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('No saved spots match “$_query”.',
                style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          ...spots.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SpotListTile(
                  spot: s,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.spotDetails, arguments: s),
                ),
              )),
      ],
    );
  }
}
