import '../../models/itinerary.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';

/// Outcome of an AI stop swap. [trip] is the updated plan when [swapped] is
/// true, otherwise the original plan unchanged. [message] explains *why* nothing
/// changed (e.g. "No Arabic food nearby.") so the UI can tell the traveller.
class StopSwapResult {
  final Trip trip;
  final bool swapped;
  final String? message;

  const StopSwapResult({required this.trip, required this.swapped, this.message});

  const StopSwapResult.unchanged(this.trip, {this.message}) : swapped = false;
}

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
  /// new stop (preserving pinned times and requested rest gaps).
  ///
  /// [prompt] is an optional per-swap request from the traveller (e.g. "a spot
  /// with great Arabic food"); the model treats it as a hard requirement. When
  /// nothing satisfies it, the result is [StopSwapResult.unchanged] with a
  /// human-readable [StopSwapResult.message]. [notes] still carries the trip's
  /// original brief so the swap keeps respecting it.
  Future<StopSwapResult> replaceStop({
    required Trip trip,
    required int dayIndex,
    required int stopIndex,
    required List<Spot> spots,
    String notes = '',
    String prompt = '',
  });
}
