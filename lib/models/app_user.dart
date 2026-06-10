import '../core/utils/json_utils.dart';
import 'enums.dart';

/// A SpotWise account. `role` decides which surfaces are unlocked
/// (traveller / contributor / admin).
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final List<String> interests;
  final List<String> savedSpotIds;
  final String? homeCity;
  final String? fcmToken;
  final bool suspended;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.user,
    this.photoUrl,
    this.interests = const [],
    this.savedSpotIds = const [],
    this.homeCity,
    this.fcmToken,
    this.suspended = false,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get canContribute => role.canContribute;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory AppUser.fromJson(String id, Map<dynamic, dynamic> json) {
    return AppUser(
      id: id,
      name: JsonUtils.asString(json['name'], 'Traveller'),
      email: JsonUtils.asString(json['email']),
      role: UserRole.fromString(JsonUtils.asStringOrNull(json['role'])),
      photoUrl: JsonUtils.asStringOrNull(json['photoUrl']),
      interests: JsonUtils.asStringList(json['interests']),
      savedSpotIds: JsonUtils.asStringList(json['savedSpots']),
      homeCity: JsonUtils.asStringOrNull(json['homeCity']),
      fcmToken: JsonUtils.asStringOrNull(json['fcmToken']),
      suspended: JsonUtils.asBool(json['suspended']),
      createdAt: JsonUtils.asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'role': role.value,
    'photoUrl': photoUrl,
    'interests': interests,
    'savedSpots': savedSpotIds,
    'homeCity': homeCity,
    'fcmToken': fcmToken,
    'suspended': suspended,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? photoUrl,
    List<String>? interests,
    List<String>? savedSpotIds,
    String? homeCity,
    String? fcmToken,
    bool? suspended,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      interests: interests ?? this.interests,
      savedSpotIds: savedSpotIds ?? this.savedSpotIds,
      homeCity: homeCity ?? this.homeCity,
      fcmToken: fcmToken ?? this.fcmToken,
      suspended: suspended ?? this.suspended,
      createdAt: createdAt,
    );
  }
}
