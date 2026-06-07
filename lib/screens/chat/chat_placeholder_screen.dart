import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/state_views.dart';

/// Placeholder for the post-MVP messaging feature (Iteration 11). Reserved here
/// so there's a real home for it when 1-to-1 chat with contributors lands.
class ChatPlaceholderScreen extends StatelessWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: EmptyView(
          icon: Icons.forum_outlined,
          title: 'Messaging is coming soon',
          message:
              'Soon you\'ll be able to message a spot\'s contributor to ask for tips and details. '
              'This is a planned post-MVP feature — the screen is reserved and ready.',
        ),
      ),
    );
  }
}
