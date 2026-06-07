import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The three user types from the pitch deck: traveller, contributor, admin.
enum UserRole {
  user,
  contributor,
  admin;

  String get value => name;

  static UserRole fromString(String? s) => UserRole.values.firstWhere(
        (e) => e.name == s,
        orElse: () => UserRole.user,
      );

  String get label => switch (this) {
        UserRole.user => 'Traveller',
        UserRole.contributor => 'Contributor',
        UserRole.admin => 'Admin',
      };

  IconData get icon => switch (this) {
        UserRole.user => Icons.explore_outlined,
        UserRole.contributor => Icons.add_location_alt_outlined,
        UserRole.admin => Icons.verified_user_outlined,
      };

  bool get canModerate => this == UserRole.admin;
  bool get canContribute => this == UserRole.contributor || this == UserRole.admin;
}

/// Moderation lifecycle of a community-submitted spot.
enum SpotStatus {
  pending,
  approved,
  rejected;

  String get value => name;

  static SpotStatus fromString(String? s) => SpotStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => SpotStatus.pending,
      );

  String get label => switch (this) {
        SpotStatus.pending => 'Pending review',
        SpotStatus.approved => 'Approved',
        SpotStatus.rejected => 'Rejected',
      };

  Color get color => switch (this) {
        SpotStatus.pending => AppColors.warning,
        SpotStatus.approved => AppColors.success,
        SpotStatus.rejected => AppColors.danger,
      };

  IconData get icon => switch (this) {
        SpotStatus.pending => Icons.hourglass_top_rounded,
        SpotStatus.approved => Icons.check_circle_rounded,
        SpotStatus.rejected => Icons.cancel_rounded,
      };
}

/// Rough cost bracket for a spot.
enum PriceRange {
  free,
  budget,
  moderate,
  premium;

  String get value => name;

  static PriceRange fromString(String? s) => PriceRange.values.firstWhere(
        (e) => e.name == s,
        orElse: () => PriceRange.moderate,
      );

  String get label => switch (this) {
        PriceRange.free => 'Free',
        PriceRange.budget => 'Budget',
        PriceRange.moderate => 'Moderate',
        PriceRange.premium => 'Premium',
      };

  /// Money-symbol badge, e.g. `$$`.
  String get symbol => switch (this) {
        PriceRange.free => 'Free',
        PriceRange.budget => '\$',
        PriceRange.moderate => '\$\$',
        PriceRange.premium => '\$\$\$',
      };
}

/// Types of in-app notification (drives icon + color in the notif center).
enum NotificationType {
  spotApproved,
  spotRejected,
  review,
  like,
  tripReminder,
  system;

  String get value => name;

  static NotificationType fromString(String? s) =>
      NotificationType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => NotificationType.system,
      );

  IconData get icon => switch (this) {
        NotificationType.spotApproved => Icons.check_circle_rounded,
        NotificationType.spotRejected => Icons.cancel_rounded,
        NotificationType.review => Icons.rate_review_rounded,
        NotificationType.like => Icons.favorite_rounded,
        NotificationType.tripReminder => Icons.alarm_rounded,
        NotificationType.system => Icons.notifications_rounded,
      };

  Color get color => switch (this) {
        NotificationType.spotApproved => AppColors.success,
        NotificationType.spotRejected => AppColors.danger,
        NotificationType.review => AppColors.info,
        NotificationType.like => AppColors.coral,
        NotificationType.tripReminder => AppColors.teal,
        NotificationType.system => AppColors.inkSoft,
      };
}

/// Lifecycle of a user report against a spot.
enum ReportStatus {
  open,
  reviewed,
  dismissed;

  String get value => name;

  static ReportStatus fromString(String? s) => ReportStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ReportStatus.open,
      );

  String get label => switch (this) {
        ReportStatus.open => 'Open',
        ReportStatus.reviewed => 'Actioned',
        ReportStatus.dismissed => 'Dismissed',
      };
}

/// Travel pace used by the AI planner to decide how many stops per day.
enum TripPace {
  relaxed,
  balanced,
  packed;

  String get value => name;

  static TripPace fromString(String? s) => TripPace.values.firstWhere(
        (e) => e.name == s,
        orElse: () => TripPace.balanced,
      );

  String get label => switch (this) {
        TripPace.relaxed => 'Relaxed',
        TripPace.balanced => 'Balanced',
        TripPace.packed => 'Packed',
      };

  /// Target number of stops per day.
  int get stopsPerDay => switch (this) {
        TripPace.relaxed => 2,
        TripPace.balanced => 3,
        TripPace.packed => 5,
      };
}

/// Time-of-day buckets for an itinerary block.
enum DayPart {
  morning,
  afternoon,
  evening;

  String get value => name;

  static DayPart fromString(String? s) => DayPart.values.firstWhere(
        (e) => e.name == s,
        orElse: () => DayPart.morning,
      );

  String get label => switch (this) {
        DayPart.morning => 'Morning',
        DayPart.afternoon => 'Afternoon',
        DayPart.evening => 'Evening',
      };

  IconData get icon => switch (this) {
        DayPart.morning => Icons.wb_twilight_rounded,
        DayPart.afternoon => Icons.wb_sunny_rounded,
        DayPart.evening => Icons.nightlight_round,
      };
}
