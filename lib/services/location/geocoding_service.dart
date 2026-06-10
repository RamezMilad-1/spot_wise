import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/json_utils.dart';

/// A geocoded place returned by the city/country search.
class GeoResult {
  final String name;
  final String displayName;
  final String country;
  final double lat;
  final double lng;

  const GeoResult({
    required this.name,
    required this.displayName,
    required this.country,
    required this.lat,
    required this.lng,
  });

  LatLng get latLng => LatLng(lat, lng);
}

/// Free city/country search via OpenStreetMap's Nominatim — no API key, no
/// billing. Powers the "Where are you going?" search on the map.
class GeocodingService {
  final http.Client _client;
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<GeoResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final uri = Uri.parse(
      '${AppConfig.nominatimBase}/search'
      '?q=${Uri.encodeQueryComponent(q)}'
      '&format=json&addressdetails=1&limit=6&featuretype=city',
    );

    final res = await _client.get(
      uri,
      headers: {
        // Required by Nominatim's usage policy (ignored by browsers on web).
        'User-Agent': AppConfig.osmUserAgent,
        'Accept': 'application/json',
      },
    );
    if (res.statusCode != 200) return [];

    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => _parse(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  GeoResult _parse(Map<String, dynamic> json) {
    final address = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : <String, dynamic>{};
    final name = JsonUtils.asString(
      address['city'] ??
          address['town'] ??
          address['village'] ??
          address['state'] ??
          address['country'] ??
          JsonUtils.asString(json['display_name']).split(',').first,
    );
    return GeoResult(
      name: name,
      displayName: JsonUtils.asString(json['display_name']),
      country: JsonUtils.asString(address['country']),
      lat: JsonUtils.asDouble(json['lat']),
      lng: JsonUtils.asDouble(json['lon']),
    );
  }
}
