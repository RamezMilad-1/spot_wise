import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/ai_planner_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: _user?.name ?? '');
  late final _homeCity = TextEditingController(text: _user?.homeCity ?? '');
  late final Set<String> _interests = {...?_user?.interests};
  String? _photo;
  bool _saving = false;

  dynamic get _user => context.read<AuthProvider>().user;

  @override
  void initState() {
    super.initState();
    _photo = context.read<AuthProvider>().user?.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _homeCity.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final uri = await services.photo.pickFromGallery();
      if (uri != null) setState(() => _photo = uri);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Couldn\'t pick that image.');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(
      name: _name.text.trim(),
      homeCity: _homeCity.text.trim(),
      interests: _interests.toList(),
      photoUrl: _photo,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppSnackbar.success(context, 'Profile updated');
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, 'Could not save changes.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Stack(
              children: [
                UserAvatar(
                  photoUrl: _photo,
                  initials: user?.initials ?? '?',
                  radius: 48,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _name,
            label: 'Name',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _homeCity,
            label: 'Home city',
            prefixIcon: Icons.home_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Interests', style: text.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We use these to recommend spots and tailor AI trips.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final i in AiPlannerProvider.suggestedInterests)
                FilterChip(
                  label: Text(i),
                  selected: _interests.contains(i),
                  onSelected: (_) => setState(() {
                    _interests.contains(i)
                        ? _interests.remove(i)
                        : _interests.add(i);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            'Save changes',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
