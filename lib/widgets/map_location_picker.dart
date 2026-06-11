import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_spacing.dart';
import 'glass_icon_button.dart';
import 'spot_marker.dart';

/// Full-screen "aim the map" picker: pan/zoom under a fixed centre pin, then
/// confirm. Pops with the chosen [LatLng] (the camera centre), or null when
/// dismissed. Pushed with a plain [MaterialPageRoute] — no named route.
class MapLocationPicker extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final String categoryId;

  const MapLocationPicker({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14,
    this.categoryId = '',
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 2,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.osmTileUrl,
                userAgentPackageName: AppConfig.osmUserAgent,
                maxZoom: 19,
              ),
            ],
          ),
          // Fixed centre pin — the map moves underneath it, so the marker's
          // centre is always the chosen point.
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: SpotMarker(
                  categoryId: widget.categoryId,
                  selected: true,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: GlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
            child: FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _controller.camera.center),
              child: const Text('Use this location'),
            ),
          ),
        ],
      ),
    );
  }
}
