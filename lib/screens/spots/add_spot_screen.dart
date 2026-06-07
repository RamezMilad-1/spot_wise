import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../models/enums.dart';
import '../../models/spot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_store.dart';
import '../../providers/spots_provider.dart';
import '../../services/location/location_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/photo_picker.dart';

/// Contributor flow: submit a new spot (camera/gallery photos + GPS capture).
/// New spots start as `pending` and enter the admin moderation queue.
class AddSpotScreen extends StatefulWidget {
  const AddSpotScreen({super.key});

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _bestTime = TextEditingController();
  final _tags = TextEditingController();

  String _categoryId = '';
  PriceRange _price = PriceRange.moderate;
  bool _isFree = false;
  bool _family = false;
  bool _hiddenGem = false;
  double? _lat;
  double? _lng;
  bool _capturing = false;
  bool _submitting = false;
  List<String> _photos = [];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _city.dispose();
    _country.dispose();
    _bestTime.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _capturing = true);
    final loc = await services.location.getCurrent();
    if (!mounted) return;
    setState(() {
      _capturing = false;
      if (loc != null) {
        _lat = loc.latitude;
        _lng = loc.longitude;
      }
    });
    if (loc == null && mounted) {
      AppSnackbar.show(
        context,
        'Couldn\'t read GPS. You can still submit — admins will verify the location.',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final tags = _tags.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final spot = Spot(
      id: '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      country: _country.text.trim(),
      city: _city.text.trim(),
      categoryId: _categoryId,
      lat: _lat ?? LocationService.fallbackCenter.latitude,
      lng: _lng ?? LocationService.fallbackCenter.longitude,
      photos: _photos,
      priceRange: _isFree ? PriceRange.free : _price,
      isFree: _isFree,
      familyFriendly: _family,
      hiddenGem: _hiddenGem,
      bestTimeToVisit: _bestTime.text.trim(),
      tags: tags,
      status: SpotStatus.pending,
      verified: false,
      submittedBy: user.id,
      submittedByName: user.name,
      createdAt: DateTime.now(),
    );

    setState(() => _submitting = true);
    try {
      await context.read<SpotsProvider>().submitSpot(spot);
      if (!mounted) return;
      AppSnackbar.success(context, 'Submitted! An admin will review it shortly.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackbar.error(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryStore>().enabled;
    if (_categoryId.isEmpty && categories.isNotEmpty) _categoryId = categories.first.id;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add a spot')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.tealMist.withValues(alpha: 0.4),
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.tealDark, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Every submission is reviewed by an admin before it goes public.',
                        style: text.bodySmall?.copyWith(color: AppColors.tealDark)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Photos', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            PhotoPickerRow(photos: _photos, onChanged: (p) => setState(() => _photos = p)),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _name,
              label: 'Name',
              hint: 'e.g. Rooftop café with a view',
              validator: (v) => Validators.required(v, 'Name'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _description,
              label: 'Description',
              hint: 'What makes it worth visiting?',
              maxLines: 4,
              validator: (v) => Validators.minLength(v, 10, 'Description'),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _categoryId.isEmpty ? null : _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      Icon(c.icon, size: 18, color: c.color),
                      const SizedBox(width: AppSpacing.sm),
                      Text(c.label),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _city,
                    label: 'City',
                    validator: (v) => Validators.required(v, 'City'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _country,
                    label: 'Country',
                    validator: (v) => Validators.required(v, 'Country'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _LocationCard(
              lat: _lat,
              lng: _lng,
              capturing: _capturing,
              onCapture: _captureLocation,
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<PriceRange>(
              initialValue: _price,
              decoration: const InputDecoration(labelText: 'Price range'),
              items: [
                for (final p in PriceRange.values)
                  DropdownMenuItem(value: p, child: Text('${p.label} (${p.symbol})')),
              ],
              onChanged: (v) => setState(() => _price = v ?? _price),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _bestTime,
              label: 'Best time to visit (optional)',
              hint: 'e.g. Sunset',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _tags,
              label: 'Tags (optional, comma-separated)',
              hint: 'Views, Romantic, Free',
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Free entry'),
              value: _isFree,
              onChanged: (v) => setState(() => _isFree = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Family-friendly'),
              value: _family,
              onChanged: (v) => setState(() => _family = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hidden gem'),
              value: _hiddenGem,
              onChanged: (v) => setState(() => _hiddenGem = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              'Submit for review',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final double? lat;
  final double? lng;
  final bool capturing;
  final VoidCallback onCapture;

  const _LocationCard({
    required this.lat,
    required this.lng,
    required this.capturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final has = lat != null && lng != null;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Icon(has ? Icons.location_on_rounded : Icons.location_off_outlined,
              color: has ? AppColors.success : scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  has
                      ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                      : 'Capture the spot\'s GPS coordinates',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: capturing ? null : onCapture,
            icon: capturing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(has ? 'Update' : 'Capture'),
          ),
        ],
      ),
    );
  }
}
