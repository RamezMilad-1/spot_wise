import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/categories.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/category_store.dart';
import '../../providers/spots_provider.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CategoryStore>();
    final spotsP = context.watch<SpotsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Toggle which categories travellers can browse and contributors can use.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final c in Categories.all)
            SwitchListTile(
              secondary: CircleAvatar(
                backgroundColor: c.color.withValues(alpha: 0.16),
                child: Icon(c.icon, color: c.color),
              ),
              title: Text(c.label),
              subtitle: Text('${spotsP.byCategory(c.id).length} live spots'),
              value: store.isEnabled(c.id),
              onChanged: (_) => store.toggle(c.id),
            ),
        ],
      ),
    );
  }
}
