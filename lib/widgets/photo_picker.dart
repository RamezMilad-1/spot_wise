import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/error_handler.dart';
import '../services/service_locator.dart';
import 'feedback.dart';
import 'network_photo.dart';

/// A grid of picked photos with an add tile (camera or gallery). Photos are
/// stored as `data:` URIs so they render and persist everywhere.
class PhotoPickerRow extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;
  final int max;

  const PhotoPickerRow({
    super.key,
    required this.photos,
    required this.onChanged,
    this.max = 5,
  });

  Future<void> _pick(BuildContext context, bool camera) async {
    try {
      final uri = camera
          ? await services.photo.pickFromCamera()
          : await services.photo.pickFromGallery();
      if (uri != null) onChanged([...photos, uri]);
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, friendlyError(e));
    }
  }

  void _remove(int index) {
    final next = [...photos]..removeAt(index);
    onChanged(next);
  }

  Future<void> _showSource(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < photos.length; i++)
          Stack(
            children: [
              NetworkPhoto(
                photos[i],
                width: 84,
                height: 84,
                radius: AppRadius.brLg,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _remove(i),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (photos.length < max)
          InkWell(
            onTap: () => _showSource(context),
            borderRadius: AppRadius.brLg,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: AppRadius.brLg,
                border: Border.all(color: scheme.outline),
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
