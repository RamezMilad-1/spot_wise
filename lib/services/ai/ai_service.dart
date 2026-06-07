import '../../models/itinerary.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';

/// Turns an [AiPlanRequest] into a day-by-day [Trip]. Implemented by
/// [GeminiAiService] (real Gemini when a key is present) which falls back to the
/// on-device [LocalItineraryGenerator].
abstract class AiService {
  /// True when a real model (Gemini) is wired up; false for the local generator.
  bool get isLive;

  Future<Trip> generateItinerary({
    required AiPlanRequest request,
    required List<Spot> spots,
    required String userId,
  });
}
