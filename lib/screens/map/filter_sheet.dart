import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/enums.dart';
import '../../models/spot_filter.dart';
import '../../providers/category_store.dart';
import '../../providers/map_provider.dart';
import '../../widgets/app_button.dart';

/// Bottom-sheet filter editor for the discovery map.
class FilterSheet extends StatefulWidget {
  final SpotFilter initial;
  final bool hasLocation;

  const FilterSheet({super.key, required this.initial, required this.hasLocation});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late SpotFilter _f = widget.initial;

  @override
  Widget build(BuildContext context) {
    final categories = context.read<CategoryStore>().enabled;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Filters', style: text.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _f = const SpotFilter()),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Category'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final c in categories)
                            FilterChip(
                              avatar: Icon(c.icon, size: 18,
                                  color: _f.categoryIds.contains(c.id) ? Colors.white : c.color),
                              label: Text(c.label),
                              selected: _f.categoryIds.contains(c.id),
                              onSelected: (_) => setState(() {
                                final ids = {..._f.categoryIds};
                                ids.contains(c.id) ? ids.remove(c.id) : ids.add(c.id);
                                _f = _f.copyWith(categoryIds: ids);
                              }),
                            ),
                        ],
                      ),
                      _label('Minimum rating'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final r in const [0.0, 3.0, 4.0, 4.5])
                            ChoiceChip(
                              label: Text(r == 0 ? 'Any' : '$r+'),
                              selected: _f.minRating == r,
                              onSelected: (_) => setState(() => _f = _f.copyWith(minRating: r)),
                            ),
                        ],
                      ),
                      _label('Price'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final p in PriceRange.values)
                            FilterChip(
                              label: Text('${p.label} (${p.symbol})'),
                              selected: _f.priceRanges.contains(p),
                              onSelected: (_) => setState(() {
                                final set = {..._f.priceRanges};
                                set.contains(p) ? set.remove(p) : set.add(p);
                                _f = _f.copyWith(priceRanges: set);
                              }),
                            ),
                        ],
                      ),
                      _label('Good for'),
                      _switch('Family-friendly', _f.familyOnly,
                          (v) => setState(() => _f = _f.copyWith(familyOnly: v))),
                      _switch('Free entry', _f.freeOnly,
                          (v) => setState(() => _f = _f.copyWith(freeOnly: v))),
                      _switch('Hidden gems', _f.hiddenGemOnly,
                          (v) => setState(() => _f = _f.copyWith(hiddenGemOnly: v))),
                      if (widget.hasLocation) ...[
                        _label('Distance'),
                        _switch(
                          'Limit by distance',
                          _f.maxDistanceKm != null,
                          (v) => setState(() => _f = v
                              ? _f.copyWith(maxDistanceKm: 10)
                              : _f.copyWith(clearDistance: true)),
                        ),
                        if (_f.maxDistanceKm != null)
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _f.maxDistanceKm!,
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  label: '${_f.maxDistanceKm!.round()} km',
                                  onChanged: (v) =>
                                      setState(() => _f = _f.copyWith(maxDistanceKm: v)),
                                ),
                              ),
                              SizedBox(
                                width: 56,
                                child: Text('${_f.maxDistanceKm!.round()} km',
                                    style: text.labelLarge),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                'Show results',
                icon: Icons.check_rounded,
                onPressed: () {
                  context.read<MapProvider>().setFilter(_f);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        value: value,
        onChanged: onChanged,
      );
}
