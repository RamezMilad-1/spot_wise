import '../core/utils/json_utils.dart';

/// A rating + comment (+ optional photos) left on a spot.
class Review {
  final String id;
  final String spotId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final double rating;
  final String comment;
  final List<String> photos;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.spotId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.comment,
    this.photos = const [],
    required this.createdAt,
  });

  factory Review.fromJson(String id, Map<dynamic, dynamic> json) {
    return Review(
      id: id,
      spotId: JsonUtils.asString(json['spotId']),
      userId: JsonUtils.asString(json['userId']),
      userName: JsonUtils.asString(json['userName'], 'Traveller'),
      userPhoto: JsonUtils.asStringOrNull(json['userPhoto']),
      rating: JsonUtils.asDouble(json['rating']),
      comment: JsonUtils.asString(json['comment']),
      photos: JsonUtils.asStringList(json['photos']),
      createdAt: JsonUtils.asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'spotId': spotId,
        'userId': userId,
        'userName': userName,
        'userPhoto': userPhoto,
        'rating': rating,
        'comment': comment,
        'photos': photos,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}
