import '../core/utils/json_utils.dart';
import 'enums.dart';

/// An entry in the in-app notification center. Written to `notifications/{id}`
/// whenever the app needs to tell a user something (spot approved, new like,
/// trip reminder…) — surfaced both here and, on mobile/desktop, as a local OS
/// notification.
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? spotId;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.system,
    this.isRead = false,
    this.spotId,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(String id, Map<dynamic, dynamic> json) {
    return NotificationItem(
      id: id,
      userId: JsonUtils.asString(json['userId']),
      title: JsonUtils.asString(json['title']),
      body: JsonUtils.asString(json['body']),
      type: NotificationType.fromString(JsonUtils.asStringOrNull(json['type'])),
      isRead: JsonUtils.asBool(json['isRead']),
      spotId: JsonUtils.asStringOrNull(json['spotId']),
      createdAt: JsonUtils.asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'isRead': isRead,
        'spotId': spotId,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        spotId: spotId,
        createdAt: createdAt,
      );
}
