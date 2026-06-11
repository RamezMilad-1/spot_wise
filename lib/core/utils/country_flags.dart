/// Country-name → flag-emoji lookup for the destination pickers.
///
/// Spots store the country as free text, so this maps common English names
/// (covering every seeded country plus popular travel destinations) to their
/// ISO-3166 alpha-2 code and renders the flag from regional indicators.
/// Unknown countries fall back to a globe so nothing ever looks broken.
library;

const String _globe = '🌍';

const Map<String, String> _iso2ByName = {
  'egypt': 'EG',
  'germany': 'DE',
  'france': 'FR',
  'italy': 'IT',
  'united kingdom': 'GB',
  'uk': 'GB',
  'england': 'GB',
  'spain': 'ES',
  'türkiye': 'TR',
  'turkey': 'TR',
  'greece': 'GR',
  'portugal': 'PT',
  'netherlands': 'NL',
  'belgium': 'BE',
  'switzerland': 'CH',
  'austria': 'AT',
  'czech republic': 'CZ',
  'czechia': 'CZ',
  'poland': 'PL',
  'hungary': 'HU',
  'croatia': 'HR',
  'ireland': 'IE',
  'norway': 'NO',
  'sweden': 'SE',
  'denmark': 'DK',
  'finland': 'FI',
  'iceland': 'IS',
  'united states': 'US',
  'usa': 'US',
  'united states of america': 'US',
  'canada': 'CA',
  'mexico': 'MX',
  'brazil': 'BR',
  'argentina': 'AR',
  'peru': 'PE',
  'colombia': 'CO',
  'chile': 'CL',
  'morocco': 'MA',
  'tunisia': 'TN',
  'south africa': 'ZA',
  'kenya': 'KE',
  'tanzania': 'TZ',
  'united arab emirates': 'AE',
  'uae': 'AE',
  'saudi arabia': 'SA',
  'qatar': 'QA',
  'jordan': 'JO',
  'lebanon': 'LB',
  'israel': 'IL',
  'india': 'IN',
  'china': 'CN',
  'japan': 'JP',
  'south korea': 'KR',
  'thailand': 'TH',
  'vietnam': 'VN',
  'indonesia': 'ID',
  'malaysia': 'MY',
  'singapore': 'SG',
  'philippines': 'PH',
  'australia': 'AU',
  'new zealand': 'NZ',
  'russia': 'RU',
  'ukraine': 'UA',
  'romania': 'RO',
  'bulgaria': 'BG',
  'serbia': 'RS',
  'slovenia': 'SI',
  'slovakia': 'SK',
  'cyprus': 'CY',
  'malta': 'MT',
};

/// Flag emoji for [country] (case-insensitive), or a globe if unknown/empty.
String countryFlag(String country) {
  final iso2 = _iso2ByName[country.trim().toLowerCase()];
  if (iso2 == null) return _globe;
  // Regional indicator symbols: 'A' (0x41) maps to U+1F1E6.
  const base = 0x1F1E6;
  return String.fromCharCodes([
    base + iso2.codeUnitAt(0) - 0x41,
    base + iso2.codeUnitAt(1) - 0x41,
  ]);
}
