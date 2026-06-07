import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/spot.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/photo_picker.dart';

/// A review form. Returns `(rating, comment, photos)` to the caller, which owns
/// the persistence + aggregate-rating update.
class AddReviewScreen extends StatefulWidget {
  final Spot spot;
  const AddReviewScreen({super.key, required this.spot});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  double _rating = 0;
  final _comment = TextEditingController();
  List<String> _photos = [];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      AppSnackbar.error(context, 'Tap the stars to rate this spot.');
      return;
    }
    if (_comment.text.trim().isEmpty) {
      AppSnackbar.error(context, 'Add a few words about your visit.');
      return;
    }
    Navigator.pop(context, (_rating, _comment.text.trim(), _photos));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Write a review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.spot.name, style: text.titleLarge),
            Text(widget.spot.location, style: text.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      iconSize: 40,
                      onPressed: () => setState(() => _rating = i.toDouble()),
                      icon: Icon(
                        _rating >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.amber,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _comment,
              label: 'Your review',
              hint: 'What made this place special?',
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Add photos (optional)', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            PhotoPickerRow(photos: _photos, onChanged: (p) => setState(() => _photos = p)),
            const SizedBox(height: AppSpacing.xxl),
            AppButton('Post review', icon: Icons.send_rounded, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
