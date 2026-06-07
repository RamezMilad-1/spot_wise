import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/json_utils.dart';
import '../../models/enums.dart';
import '../../models/itinerary.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';
import 'ai_service.dart';
import 'local_itinerary_generator.dart';

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
    final approved = spots.where((s) => s.status == SpotStatus.approved).toList();
    if (!AppConfig.hasGemini) {
      return _fallback.generate(request, approved, userId);
    }
    try {
      final uri = Uri.parse('$_endpoint/$_model:generateContent?key=${AppConfig.geminiApiKey}');
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': _buildPrompt(request, approved)}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'responseMimeType': 'application/json',
          },
        }),
      );
      if (res.statusCode != 200) throw Exception('Gemini ${res.statusCode}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final trip = _toTrip(parsed, request, approved, userId);
      return trip ?? _fallback.generate(request, approved, userId);
    } catch (_) {
      // Any hiccup (quota, model, parsing) → the demo still works.
      return _fallback.generate(request, approved, userId);
    }
  }

  String _buildPrompt(AiPlanRequest req, List<Spot> spots) {
    final relevant = spots
        .where((s) => s.city.toLowerCase().contains(req.destination.trim().toLowerCase()))
        .toList();
    final pool = (relevant.isNotEmpty ? relevant : spots).take(40).toList();
    final spotLines = pool
        .map((s) =>
            '- id:${s.id} | ${s.name} | ${Categories.labelFor(s.categoryId)} | ${s.city} | tags:${s.tags.join(', ')} | rating:${s.rating}')
        .join('\n');

    return '''
You are SpotWise, an expert local travel planner. Design a ${req.dayCount}-day itinerary for ${req.destination}${req.country.isNotEmpty ? ', ${req.country}' : ''}.
Traveller interests: ${req.interests.isEmpty ? 'general sightseeing' : req.interests.join(', ')}.
Budget: ${req.budget.label}. Pace: ${req.pace.label} (about ${req.pace.stopsPerDay} stops per day).

Choose ONLY from these approved spots and reference each by its exact id:
$spotLines

Return STRICT JSON (no markdown, no commentary) shaped exactly like:
{"days":[{"title":"short day title","summary":"one sentence","stops":[{"spotId":"the id","dayPart":"morning|afternoon|evening","time":"09:00","note":"one short practical tip"}]}]}
Spread the stops across morning, afternoon and evening, cluster nearby places to avoid backtracking, and keep roughly ${req.pace.stopsPerDay} stops per day.
''';
  }

  Trip? _toTrip(Map<String, dynamic> json, AiPlanRequest req, List<Spot> spots, String userId) {
    final byId = {for (final s in spots) s.id: s};
    final byName = {for (final s in spots) s.name.toLowerCase(): s};
    final daysJson = (json['days'] as List?) ?? const [];

    final days = <TripDay>[];
    for (var i = 0; i < daysJson.length; i++) {
      final dj = Map<String, dynamic>.from(daysJson[i] as Map);
      final stopsJson = (dj['stops'] as List?) ?? const [];
      final stops = <TripStop>[];
      for (final raw in stopsJson) {
        final m = Map<String, dynamic>.from(raw as Map);
        final spot = byId[JsonUtils.asString(m['spotId'])] ??
            byName[JsonUtils.asString(m['name']).toLowerCase()];
        if (spot == null) continue;
        stops.add(TripStop(
          spotId: spot.id,
          name: spot.name,
          photo: spot.coverPhoto,
          categoryId: spot.categoryId,
          lat: spot.lat,
          lng: spot.lng,
          dayPart: DayPart.fromString(JsonUtils.asStringOrNull(m['dayPart'])),
          suggestedTime: JsonUtils.asString(m['time']),
          note: JsonUtils.asString(m['note']),
        ));
      }
      if (stops.isEmpty) continue;
      days.add(TripDay(
        dayNumber: days.length + 1,
        date: req.startDate.add(Duration(days: days.length)),
        title: JsonUtils.asString(dj['title'], 'Day ${days.length + 1}'),
        summary: JsonUtils.asString(dj['summary']),
        stops: stops,
      ));
    }

    if (days.isEmpty) return null;
    return Trip(
      id: '',
      userId: userId,
      destination: req.destination,
      country: req.country,
      lat: req.lat,
      lng: req.lng,
      startDate: req.startDate,
      endDate: req.startDate.add(Duration(days: (days.length - 1).clamp(0, 365))),
      days: days,
      aiGenerated: true,
      coverPhoto: days.first.stops.first.photo,
      notes: 'Generated by Gemini for ${req.interests.isEmpty ? 'your trip' : req.interests.join(', ')}.',
      createdAt: DateTime.now(),
    );
  }
}
