import '../core/utils/json_utils.dart';
import 'enums.dart';

/// A user-filed report against a spot, surfaced in the admin panel.
class Report {
  final String id;
  final String spotId;
  final String spotName;
  final String userId;
  final String userName;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.spotId,
    required this.spotName,
    required this.userId,
    required this.userName,
    required this.reason,
    this.status = ReportStatus.open,
    required this.createdAt,
  });

  factory Report.fromJson(String id, Map<dynamic, dynamic> json) {
    return Report(
      id: id,
      spotId: JsonUtils.asString(json['spotId']),
      spotName: JsonUtils.asString(json['spotName']),
      userId: JsonUtils.asString(json['userId']),
      userName: JsonUtils.asString(json['userName'], 'Traveller'),
      reason: JsonUtils.asString(json['reason']),
      status: ReportStatus.fromString(JsonUtils.asStringOrNull(json['status'])),
      createdAt: JsonUtils.asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'spotId': spotId,
    'spotName': spotName,
    'userId': userId,
    'userName': userName,
    'reason': reason,
    'status': status.value,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  Report copyWith({ReportStatus? status}) => Report(
    id: id,
    spotId: spotId,
    spotName: spotName,
    userId: userId,
    userName: userName,
    reason: reason,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}
