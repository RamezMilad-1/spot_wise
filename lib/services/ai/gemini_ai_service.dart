import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const Distance _distance = Distance();

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
      final text = await _generate(_buildPrompt(request, approved));
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final trip = _toTrip(parsed, request, approved, userId);
      return trip ?? _fallback.generate(request, approved, userId);
    } catch (_) {
      // Any hiccup (quota, model, parsing) → the demo still works.
      return _fallback.generate(request, approved, userId);
    }
  }

  @override
  Future<StopSwapResult> replaceStop({
    required Trip trip,
    required int dayIndex,
    required int stopIndex,
    required List<Spot> spots,
    String notes = '',
    String prompt = '',
  }) async {
    if (dayIndex < 0 || dayIndex >= trip.days.length) {
      return StopSwapResult.unchanged(trip);
    }
    final day = trip.days[dayIndex];
    if (stopIndex < 0 || stopIndex >= day.stops.length) {
      return StopSwapResult.unchanged(trip);
    }
    final reject = day.stops[stopIndex];

    final usedIds = trip.days.expand((d) => d.stops).map((s) => s.spotId).toSet();
    final candidates = _replacementCandidates(
      reject,
      spots.where((s) => s.status == SpotStatus.approved),
      usedIds,
    );
    if (candidates.isEmpty) {
      return StopSwapResult.unchanged(
        trip,
        message: 'No other nearby spots to swap in.',
      );
    }

    final wish = prompt.trim();
    Spot? choice;
    var note = '';
    if (AppConfig.hasGemini) {
      try {
        final text = await _generate(
          _buildReplacePrompt(trip, day, reject, candidates, notes, wish),
        );
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        final id = JsonUtils.asString(parsed['spotId']);
        if (id.isEmpty) {
          // The model decided no alternative satisfies the request.
          final reason = JsonUtils.asString(parsed['reason']);
          return StopSwapResult.unchanged(
            trip,
            message: reason.isNotEmpty
                ? reason
                : 'Nothing nearby matches that request.',
          );
        }
        final byId = {for (final s in candidates) s.id: s};
        choice = byId[id];
        note = JsonUtils.asString(parsed['note']);
      } catch (_) {
        // Fall through to the local pick below.
      }
    }
    if (choice == null) {
      choice = _fallback.pickReplacement(
        reject: reject,
        candidates: candidates,
        prompt: wish,
      );
      if (choice == null) {
        // Only reachable when a wish was set and nothing local matched it.
        return StopSwapResult.unchanged(
          trip,
          message: 'Couldn\'t find a nearby spot matching “$wish”.',
        );
      }
    }
    if (note.isEmpty) note = _fallback.noteFor(choice);

    final newStop = TripStop(
      spotId: choice.id,
      name: choice.name,
      photo: choice.coverPhoto,
      categoryId: choice.categoryId,
      lat: choice.lat,
      lng: choice.lng,
      note: note,
      estimatedCost: TripEstimator.stopCost(choice),
      durationMinutes: TripEstimator.durationMinutes(choice.categoryId),
    );

    final newStops = [...day.stops]..[stopIndex] = newStop;
    final newDays = [...trip.days];
    newDays[dayIndex] = day.copyWith(
      stops: newStops,
      // Keep the day summary honest if it name-checked the old stop.
      summary: day.summary.replaceAll(reject.name, choice.name),
    );
    // Re-schedule the whole plan — later stops shift automatically when the
    // new spot needs more (or less) time; pinned anchors and rest gaps hold.
    final scheduled = TripEstimator.schedule(
      newDays,
      gapMinutes: trip.restMinutes,
    );
    return StopSwapResult(
      swapped: true,
      trip: trip.copyWith(
        days: scheduled,
        estimatedCost:
            trip.estimatedCost - reject.estimatedCost + newStop.estimatedCost,
      ),
    );
  }

  /// Calls Gemini and returns the model's text (strict-JSON mode).
  Future<String> _generate(String prompt) async {
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
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          // Low temperature: instruction-following matters more than flair.
          'temperature': 0.4,
          'responseMimeType': 'application/json',
        },
      }),
    );
    if (res.statusCode != 200) throw Exception('Gemini ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  List<Spot> _candidatePool(AiPlanRequest req, List<Spot> spots) {
    bool near(Spot s) {
      if (req.lat == null || req.lng == null) return false;
      return _distance.as(
            LengthUnit.Kilometer,
            LatLng(req.lat!, req.lng!),
            s.latLng,
          ) <=
          60;
    }

    final d = req.destination.trim().toLowerCase();
    final relevant = spots
        .where(
          (s) =>
              (d.isNotEmpty &&
                  ('${s.city} ${s.country}'.toLowerCase().contains(d))) ||
              near(s),
        )
        .toList();
    final pool = relevant.isNotEmpty ? relevant : spots;
    return pool.take(40).toList();
  }

  /// Nearby, unused alternatives for a stop swap: same city as the rejected
  /// stop or within ~60 km, best-rated first, capped at 25.
  List<Spot> _replacementCandidates(
    TripStop reject,
    Iterable<Spot> approved,
    Set<String> usedIds,
  ) {
    final rejectPoint = LatLng(reject.lat, reject.lng);
    final list =
        approved
            .where(
              (s) =>
                  !usedIds.contains(s.id) &&
                  _distance.as(LengthUnit.Kilometer, rejectPoint, s.latLng) <=
                      60,
            )
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(25).toList();
  }

  /// One grounding line per catalog spot — everything the model needs to pick
  /// well: quality, cost, timing and geography.
  String _spotLine(Spot s) =>
      '- id:${s.id} | ${s.name} | ${Categories.labelFor(s.categoryId)} | ${s.city} '
      '| price:${s.priceRange.symbol} (~\$${TripEstimator.stopCost(s).round()}) '
      '| ~${TripEstimator.durationMinutes(s.categoryId)}min '
      '| rating:${s.rating}/5 (${s.reviewCount} reviews) '
      '| best time:${s.bestTimeToVisit.isEmpty ? 'any' : s.bestTimeToVisit} '
      '| loc:${s.lat.toStringAsFixed(4)},${s.lng.toStringAsFixed(4)} '
      '| tags:${s.tags.join(', ')} '
      '| "${_snippet(s.description)}"';

  static String _snippet(String description) {
    final clean = description.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 100 ? clean : '${clean.substring(0, 100)}…';
  }

  String _buildPrompt(AiPlanRequest req, List<Spot> spots) {
    final pool = _candidatePool(req, spots);
    final spotLines = pool.map(_spotLine).join('\n');

    final budgetLine = req.budgetCap != null
        ? 'Keep the whole trip under about \$${req.budgetCap!.round()} total — favour free and budget spots when it helps stay under.'
        : 'Aim for a ${req.budget.label.toLowerCase()} budget.';
    final start = DateFormat('EEEE, MMM d, yyyy').format(req.startDate);
    final notes = req.notes.trim();

    return '''
You are SpotWise's veteran local tour guide and trip designer for ${req.destination}${req.country.isNotEmpty ? ', ${req.country}' : ''}.
You plan routes like a local: you know which neighbourhoods sit next to each other, what is lovely in the morning and what only comes alive after dark.

THE TRAVELLER'S BRIEF
- Trip: ${req.dayCount} day(s) starting $start.
- Interests: ${req.interests.isEmpty ? 'general sightseeing' : req.interests.join(', ')}.
- Pace: ${req.pace.label} — about ${req.pace.stopsPerDay} stops per day.
- Budget: $budgetLine
${notes.isEmpty ? '' : '- Special requests (hard requirements — they override everything below): "$notes"\n'}
THE ONLY PLACES YOU MAY USE — SpotWise's approved catalog, reference each by its exact id:
$spotLines

HOW TO PLAN — think this through BEFORE writing the answer:
1. Quality first: prefer higher-rated spots when options are otherwise similar.
2. Route like a local: use the loc coordinates to group nearby spots into the same day, and order each day's stops so the traveller moves in one direction along an efficient route — never zig-zag across the city and back.
3. Time of day matters: morning-best spots early, sunset viewpoints late afternoon, nightlife last; weave food and café stops in around natural meal times.
4. Respect the pace and the budget.
5. Each day starts at 09:00 and should finish by about 22:00 (later only if the traveller asks for nightlife). If the special requests add long rests, plan FEWER stops per day so the day still ends on time.
6. If any special request conflicts with rules 1–5, the special request wins.

YOUR ANSWER — return STRICT JSON only (no markdown, no commentary), exactly this shape:
{"restMinutes":0,"days":[{"title":"short evocative day title","summary":"one helpful sentence about the day's flow","stops":[{"spotId":"<exact id>","note":"one specific practical tip, 12 words max"}]}]}

JSON rules:
- "restMinutes": extra rest minutes the traveller wants between stops — 0 unless the special requests ask for breaks (e.g. "an hour rest between spots" → 60).
- A stop object may ADDITIONALLY include "startTime":"HH:MM" (24-hour) — but ONLY when the traveller explicitly asked for that stop at a specific time, or for at most ONE truly time-critical stop per day (e.g. a sunset viewpoint). Every other stop must contain ONLY "spotId" and "note": SpotWise computes their times itself.
- "note" must be concrete (what to order, where to stand, what to skip) — never generic filler like "enjoy the visit".
- Order each day's stops morning → evening, about ${req.pace.stopsPerDay} per day, and use only ids from the catalog.
''';
  }

  String _buildReplacePrompt(
    Trip trip,
    TripDay day,
    TripStop reject,
    List<Spot> candidates,
    String notes,
    String wish,
  ) {
    final date = day.date != null
        ? DateFormat('EEEE, MMM d').format(day.date!)
        : 'Day ${day.dayNumber}';
    final dayLines = day.stops
        .map(
          (s) =>
              '- ${s.suggestedTime.isEmpty ? '' : '${s.suggestedTime} '}${s.name} '
              '(${Categories.labelFor(s.categoryId)}, ~${s.durationMinutes}min)'
              '${identical(s, reject) || s.spotId == reject.spotId ? '   ← REPLACE THIS ONE' : ''}',
        )
        .join('\n');
    final candidateLines = candidates.map(_spotLine).join('\n');
    final trimmedNotes = notes.trim();

    return '''
You are SpotWise's veteran local tour guide for ${trip.destination}. A traveller has a finished day plan but dislikes one stop and wants a better replacement.

THE DAY ($date — "${day.title.isEmpty ? 'Day ${day.dayNumber}' : day.title}"):
$dayLines
${trimmedNotes.isEmpty ? '' : '\nTraveller\'s original requests to keep respecting: "$trimmedNotes"\n'}${wish.isEmpty ? '' : '\nFor THIS replacement the traveller specifically asked for: "$wish" — treat it as a hard requirement.\n'}
ALTERNATIVES — choose exactly ONE by its exact id (never a spot already in the plan):
$candidateLines

Choose the alternative that best keeps the day's route efficient (close to the stops before and after the empty slot), suits that time of day, and has strong ratings${wish.isEmpty ? '' : ', AND genuinely satisfies the traveller\'s specific request above'}.
${wish.isEmpty ? '' : 'If NONE of the alternatives reasonably satisfy that request, do not force a poor match — instead set "spotId" to null and give a short friendly "reason" (e.g. what is missing nearby).\n'}
Return STRICT JSON only: {"spotId":"<exact id or null>","note":"one specific practical tip, 12 words max","reason":"<only when spotId is null>"}
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
    final restMinutes = JsonUtils.asInt(json['restMinutes']).clamp(0, 240);

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
        // Times are computed by the estimator, not trusted from the model —
        // except an explicit anchor, which the scheduler honours as "not
        // earlier than".
        stops.add(
          TripStop(
            spotId: spot.id,
            name: spot.name,
            photo: spot.coverPhoto,
            categoryId: spot.categoryId,
            lat: spot.lat,
            lng: spot.lng,
            note: JsonUtils.asString(m['note']),
            pinnedTime: _validHhmm(JsonUtils.asString(m['startTime'])),
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
    final days = TripEstimator.schedule(rawDays, gapMinutes: restMinutes);
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
      restMinutes: restMinutes,
      notes:
          'Generated by Gemini for ${req.interests.isEmpty ? 'your trip' : req.interests.join(', ')}.',
      createdAt: DateTime.now(),
    );
  }

  /// Returns the value when it's a valid 24h "HH:MM", else ''.
  static String _validHhmm(String value) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (m == null) return '';
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return '';
    return value.trim();
  }
}
