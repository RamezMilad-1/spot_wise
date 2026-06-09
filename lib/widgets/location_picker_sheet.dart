import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/debouncer.dart';
import '../services/location/geocoding_service.dart';
import '../services/service_locator.dart';

/// Lets the user pick an origin to search around — either their GPS location or
/// a geocoded place. Returns the chosen `(position, label)`, or null if dismissed.
Future<(LatLng, String)?> pickLocation(BuildContext context) {
  return showModalBottomSheet<(LatLng, String)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();
  List<GeoResult> _results = const [];
  bool _searching = false;
  bool _locating = false;

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String q) => _debouncer.run(() => _search(q));

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      if (mounted) setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final r = await services.geocoding.search(q);
      if (mounted) {
        setState(() {
          _results = r;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = const [];
          _searching = false;
        });
      }
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final loc = await services.location.getCurrent();
    if (!mounted) return;
    setState(() => _locating = false);
    if (loc != null) {
      Navigator.pop(context, (loc, 'My location'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t read your location — search a place instead.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find spots near…', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.tealMist,
                child: _locating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, color: AppColors.tealDark),
              ),
              title: const Text('Use my current location'),
              onTap: _locating ? null : _useMyLocation,
            ),
            const Divider(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search a city or place',
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(r.name),
                      subtitle: Text(r.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, (r.latLng, r.name)),
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
