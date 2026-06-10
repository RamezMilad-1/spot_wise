import 'package:flutter/material.dart';

import 'network_photo.dart';

/// Circular avatar — shows the user's photo if present, otherwise their
/// initials on a neutral background.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.initials,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: NetworkPhoto(photoUrl, width: radius * 2, height: radius * 2),
      );
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outline),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
