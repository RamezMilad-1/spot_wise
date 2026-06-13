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

  /// Replaces one stop of an existing plan with an AI-chosen alternative and
  /// returns the updated trip — the rest of the day is re-scheduled around the
  /// new stop (preserving pinned times and requested rest gaps). Returns the
  /// trip unchanged when no alternative exists.
  Future<Trip> replaceStop({
    required Trip trip,
    required int dayIndex,
    required int stopIndex,
    required List<Spot> spots,
    String notes = '',
  });
}
