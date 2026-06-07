import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'network_photo.dart';

/// Circular avatar — shows the user's photo if present, otherwise their
/// initials on a branded background.
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
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: NetworkPhoto(photoUrl, width: radius * 2, height: radius * 2),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.tealMist,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.tealDark,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
