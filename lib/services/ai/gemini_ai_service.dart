import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/json_utils.dart';
import '../../models/enums.dart';
import '../../models/itinerary.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';
import 'ai_service.dart';
import 'local_itinerary_generator.dart';
import 'trip_estimator.dart';

/// Google Gemini itinerary planner over the `generativelanguage` REST API
/// (raw `http`, key from `.env`). Grounds the model on the app's approved spots
/// and asks for strict JSON.
///
/// When `GEMINI_API_KEY` is absent — or any call fails — it transparently falls
/// back to [LocalItineraryGenerator], so the AI planner always produces a result.
class GeminiAiService implements AiService {
  static const String _model = 'gemini-2.0-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final http.Client _client;
  final LocalItineraryGenerator _fallback;

  GeminiAiService({http.Client? client, LocalItineraryGenerator? fallback})
    : _client = client ?? http.Client(),
      _fallback = fallback ?? LocalItineraryGenerator();

  @override
  bool get isLive => AppConfig.hasGemini;

  @override
  Future<Trip> generateItinerary({
    required AiPlanRequest request,
    required List<Spot> spots,
    required String userId,
  }) async {
    final approved = spots
        .where((s) => s.status == SpotStatus.approved)
        .toList();
    if (!AppConfig.hasGemini) {
      return _fallback.generate(request, approved, userId);
    }
    try {
      final uri = Uri.parse(
        '$_endpoint/$_model:generateContent?key=${AppConfig.geminiApiKey}',
      );
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': _buildPrompt(request, approved)},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.9,
            'responseMimeType': 'application/json',
          },
        }),
      );
      if (res.statusCode != 200) throw Exception('Gemini ${res.statusCode}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final trip = _toTrip(parsed, request, approved, userId);
      return trip ?? _fallback.generate(request, approved, userId);
    } catch (_) {
      // Any hiccup (quota, model, parsing) → the demo still works.
      return _fallback.generate(request, approved, userId);
    }
  }

  List<Spot> _candidatePool(AiPlanRequest req, List<Spot> spots) {
    bool near(Spot s) {
      if (req.lat == null || req.lng == null) return false;
      return const Distance().as(
            LengthUnit.Kilometer,
            LatLng(req.lat!, req.lng!),
            s.latLng,
          ) <=
          60;
    }

    final d = req.destination.trim().toLowerCase();
    final relevant = spots
        .where(
          (s) => (d.isNotEmpty && s.city.toLowerCase().contains(d)) || near(s),
        )
        .toList();
    final pool = relevant.isNotEmpty ? relevant : spots;
    return pool.take(40).toList();
  }

  String _buildPrompt(AiPlanRequest req, List<Spot> spots) {
    final pool = _candidatePool(req, spots);
    final spotLines = pool
        .map(
          (s) =>
              '- id:${s.id} | ${s.name} | ${Categories.labelFor(s.categoryId)} | ${s.city} '
              '| price:${s.priceRange.symbol} (~\$${TripEstimator.stopCost(s).round()}) '
              '| ~${TripEstimator.durationMinutes(s.categoryId)}min '
              '| rating:${s.rating} '
              '| loc:${s.lat.toStringAsFixed(4)},${s.lng.toStringAsFixed(4)} '
              '| tags:${s.tags.join(', ')}',
        )
        .join('\n');

    final budgetLine = req.budgetCap != null
        ? 'Keep the whole trip under about \$${req.budgetCap!.round()} total — favour free and budget spots when it helps stay under.'
        : 'Aim for a ${req.budget.label.toLowerCase()} budget.';

    return '''
You are SpotWise, an expert local travel planner. Design a ${req.dayCount}-day itinerary for ${req.destination}${req.country.isNotEmpty ? ', ${req.country}' : ''}.
Explorer interests: ${req.interests.isEmpty ? 'general sightseeing' : req.interests.join(', ')}.
Pace: ${req.pace.label} (about ${req.pace.stopsPerDay} stops per day). $budgetLine

Choose ONLY from these approved spots and reference each by its exact id. Use the loc lat,lng to cluster nearby places on the same day and avoid backtracking:
$spotLines

Return STRICT JSON (no markdown, no commentary) shaped exactly like:
{"days":[{"title":"short day title","summary":"one sentence","stops":[{"spotId":"the id","note":"one short practical tip"}]}]}
Order each day's stops from morning to evening and keep roughly ${req.pace.stopsPerDay} stops per day. SpotWise computes exact visit times and the budget itself, so you don't need to.
''';
  }

  Trip? _toTrip(
    Map<String, dynamic> json,
    AiPlanRequest req,
    List<Spot> spots,
    String userId,
  ) {
    final byId = {for (final s in spots) s.id: s};
    final byName = {for (final s in spots) s.name.toLowerCase(): s};
    final daysJson = (json['days'] as List?) ?? const [];

    final rawDays = <TripDay>[];
    for (var i = 0; i < daysJson.length; i++) {
      final dj = Map<String, dynamic>.from(daysJson[i] as Map);
      final stopsJson = (dj['stops'] as List?) ?? const [];
      final stops = <TripStop>[];
      for (final raw in stopsJson) {
        final m = Map<String, dynamic>.from(raw as Map);
        final spot =
            byId[JsonUtils.asString(m['spotId'])] ??
            byName[JsonUtils.asString(m['name']).toLowerCase()];
        if (spot == null) continue;
        // Times + day-parts are computed by the estimator, not trusted from the
        // model, so the schedule is always realistic.
        stops.add(
          TripStop(
            spotId: spot.id,
            name: spot.name,
            photo: spot.coverPhoto,
            categoryId: spot.categoryId,
            lat: spot.lat,
            lng: spot.lng,
            note: JsonUtils.asString(m['note']),
            estimatedCost: TripEstimator.stopCost(spot),
            durationMinutes: TripEstimator.durationMinutes(spot.categoryId),
          ),
        );
      }
      if (stops.isEmpty) continue;
      rawDays.add(
        TripDay(
          dayNumber: rawDays.length + 1,
          date: req.startDate.add(Duration(days: rawDays.length)),
          title: JsonUtils.asString(dj['title'], 'Day ${rawDays.length + 1}'),
          summary: JsonUtils.asString(dj['summary']),
          stops: stops,
        ),
      );
    }

    if (rawDays.isEmpty) return null;
    final days = TripEstimator.schedule(rawDays);
    final cost = TripEstimator.total(days, pace: req.pace);
    return Trip(
      id: '',
      userId: userId,
      destination: req.destination,
      country: req.country,
      lat: req.lat,
      lng: req.lng,
      startDate: req.startDate,
      endDate: req.startDate.add(
        Duration(days: (days.length - 1).clamp(0, 365)),
      ),
      days: days,
      aiGenerated: true,
      coverPhoto: days.first.stops.first.photo,
      estimatedCost: cost,
      budgetCap: req.budgetCap,
      notes:
          'Generated by Gemini for ${req.interests.isEmpty ? 'your trip' : req.interests.join(', ')}.',
      createdAt: DateTime.now(),
    );
  }
}
