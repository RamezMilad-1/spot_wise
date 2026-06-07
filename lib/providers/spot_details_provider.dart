import 'package:flutter/foundation.dart';

import '../core/utils/error_handler.dart';
import '../models/report.dart';
import '../models/review.dart';
import '../models/spot.dart';
import '../services/service_locator.dart';

/// Scoped to a single spot's detail screen: its reviews, adding a review (which
/// updates the aggregate rating) and filing a report.
class SpotDetailsProvider extends ChangeNotifier {
  Spot _spot;
  SpotDetailsProvider(this._spot) {
    loadReviews();
  }

  Spot get spot => _spot;

  List<Review> _reviews = [];
  bool _loading = true;
  String? _error;

  List<Review> get reviews => _reviews;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadReviews() async {
    _loading = true;
    notifyListeners();
    try {
      _reviews = await services.backend.getReviews(_spot.id);
      _error = null;
    } catch (e) {
      _error = friendlyError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addReview({
    required double rating,
    required String comment,
    List<String> photos = const [],
  }) async {
    final user = services.auth.currentUser;
    final review = Review(
      id: '',
      spotId: _spot.id,
      userId: user?.id ?? '',
      userName: user?.name ?? 'You',
      userPhoto: user?.photoUrl,
      rating: rating,
      comment: comment,
      photos: photos,
      createdAt: DateTime.now(),
    );
    await services.backend.addReview(review);

    final newCount = _spot.reviewCount + 1;
    final newRating = ((_spot.rating * _spot.reviewCount) + rating) / newCount;
    _spot = _spot.copyWith(
      rating: double.parse(newRating.toStringAsFixed(2)),
      reviewCount: newCount,
    );
    await services.backend.updateSpot(_spot);
    await loadReviews();
  }

  Future<void> report(String reason) async {
    final user = services.auth.currentUser;
    await services.backend.addReport(Report(
      id: '',
      spotId: _spot.id,
      spotName: _spot.name,
      userId: user?.id ?? '',
      userName: user?.name ?? 'Anonymous',
      reason: reason,
      createdAt: DateTime.now(),
    ));
  }
}
