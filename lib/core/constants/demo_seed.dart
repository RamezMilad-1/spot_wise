import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/notification_item.dart';
import '../../models/review.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';
import '../../services/ai/trip_estimator.dart';

/// Realistic demo content loaded the first time the app runs on the local
/// backend, so every screen (feed, map, trips, admin queue, notifications)
/// looks complete with zero configuration.
///
/// Photos use picsum.photos seeded URLs — reliable, attractive placeholders so
/// nothing ever renders as a broken image during a demo.
class DemoSeed {
  DemoSeed._();

  static String photo(String seed) => 'https://picsum.photos/seed/$seed/900/640';
  static DateTime _daysAgo(int d) => DateTime.now().subtract(Duration(days: d));

  /// Demo logins surfaced on the sign-in screen.
  static const Map<String, String> demoPasswords = {
    'demo@spotwise.app': 'spotwise',
    'contributor@spotwise.app': 'spotwise',
    'admin@spotwise.app': 'spotwise',
  };

  static List<AppUser> users() => [
        AppUser(
          id: 'u_traveller',
          name: 'Maya Rivera',
          email: 'demo@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-maya'),
          interests: const ['Food', 'History', 'Views', 'Art'],
          savedSpotIds: const ['s_pyramids', 's_klunkerkranich', 's_trastevere'],
          homeCity: 'Berlin',
          createdAt: _daysAgo(120),
        ),
        AppUser(
          id: 'u_contributor',
          name: 'Karim Hassan',
          email: 'contributor@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-karim'),
          interests: const ['Hidden gems', 'Food', 'Markets'],
          homeCity: 'Cairo',
          createdAt: _daysAgo(90),
        ),
        AppUser(
          id: 'u_admin',
          name: 'Nadia Admin',
          email: 'admin@spotwise.app',
          role: UserRole.admin,
          photoUrl: photo('avatar-nadia'),
          interests: const ['Moderation'],
          homeCity: 'Berlin',
          createdAt: _daysAgo(200),
        ),
        AppUser(
          id: 'u_sofia',
          name: 'Sofia Lindqvist',
          email: 'sofia@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-sofia'),
          interests: const ['Art', 'Coffee', 'Nightlife'],
          homeCity: 'Paris',
          createdAt: _daysAgo(64),
        ),
        AppUser(
          id: 'u_marco',
          name: 'Marco Bianchi',
          email: 'marco@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-marco'),
          interests: const ['Food', 'History'],
          homeCity: 'Rome',
          createdAt: _daysAgo(48),
        ),
        AppUser(
          id: 'u_lukas',
          name: 'Lukas Weber',
          email: 'lukas@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-lukas'),
          interests: const ['Nature', 'Adventure'],
          homeCity: 'Berlin',
          createdAt: _daysAgo(20),
        ),
        AppUser(
          id: 'u_aisha',
          name: 'Aisha Khan',
          email: 'aisha@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-aisha'),
          interests: const ['Markets', 'Food'],
          homeCity: 'Cairo',
          suspended: true,
          createdAt: _daysAgo(12),
        ),
        AppUser(
          id: 'u_yuki',
          name: 'Yuki Tanaka',
          email: 'yuki@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-yuki'),
          interests: const ['Art', 'Food', 'Architecture'],
          homeCity: 'Tokyo',
          createdAt: _daysAgo(54),
        ),
        AppUser(
          id: 'u_emma',
          name: 'Emma Clarke',
          email: 'emma@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-emma'),
          interests: const ['Museums', 'Coffee', 'Shopping'],
          homeCity: 'London',
          createdAt: _daysAgo(33),
        ),
        AppUser(
          id: 'u_diego',
          name: 'Diego Morales',
          email: 'diego@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-diego'),
          interests: const ['Beach', 'Nightlife', 'Food'],
          homeCity: 'Barcelona',
          createdAt: _daysAgo(27),
        ),
        AppUser(
          id: 'u_omar',
          name: 'Omar Farouk',
          email: 'omar@spotwise.app',
          role: UserRole.user,
          photoUrl: photo('avatar-omar'),
          interests: const ['History', 'Views'],
          homeCity: 'Cairo',
          createdAt: _daysAgo(18),
        ),
      ];

  static Spot _spot({
    required String id,
    required String name,
    required String city,
    required String country,
    required String category,
    required double lat,
    required double lng,
    required String desc,
    double rating = 4.6,
    int reviews = 0,
    PriceRange price = PriceRange.moderate,
    bool free = false,
    bool family = false,
    bool gem = false,
    bool featured = false,
    String best = '',
    List<String> tags = const [],
    SpotStatus status = SpotStatus.approved,
    bool verified = true,
    int likes = 0,
    int saves = 0,
    int ageDays = 30,
    String by = 'u_contributor',
    String byName = 'Karim Hassan',
  }) {
    return Spot(
      id: id,
      name: name,
      description: desc,
      country: country,
      city: city,
      categoryId: category,
      lat: lat,
      lng: lng,
      photos: [photo('$id-1'), photo('$id-2'), photo('$id-3')],
      rating: rating,
      reviewCount: reviews,
      priceRange: price,
      isFree: free,
      familyFriendly: family,
      hiddenGem: gem,
      featured: featured,
      bestTimeToVisit: best,
      tags: tags,
      status: status,
      verified: verified && status == SpotStatus.approved,
      submittedBy: by,
      submittedByName: byName,
      approvedBy: status == SpotStatus.approved ? 'u_admin' : null,
      likeCount: likes,
      saveCount: saves,
      createdAt: _daysAgo(ageDays),
    );
  }

  static List<Spot> spots() => [
        // ── Cairo ────────────────────────────────────────────────────────────
        _spot(
          id: 's_pyramids', name: 'Pyramids of Giza', city: 'Cairo', country: 'Egypt',
          category: 'landmark', lat: 29.9792, lng: 31.1342,
          desc: 'The last surviving wonder of the ancient world. Go at opening time to beat the heat and the crowds, then ride out into the desert for the classic three-pyramid panorama.',
          rating: 4.9, reviews: 1284, price: PriceRange.budget, family: true, featured: true,
          best: 'Early morning', tags: const ['UNESCO', 'Iconic', 'Desert'], likes: 980, saves: 1520, ageDays: 80,
        ),
        _spot(
          id: 's_egyptian_museum', name: 'The Egyptian Museum', city: 'Cairo', country: 'Egypt',
          category: 'museum', lat: 30.0478, lng: 31.2336,
          desc: 'Home to Tutankhamun\'s treasures and floor after floor of antiquities. A must for history lovers — allow at least half a day.',
          rating: 4.7, reviews: 642, price: PriceRange.budget, family: true,
          best: 'Weekday mornings', tags: const ['History', 'Indoor'], likes: 420, saves: 510, ageDays: 70,
        ),
        _spot(
          id: 's_khan', name: 'Khan el-Khalili', city: 'Cairo', country: 'Egypt',
          category: 'shopping', lat: 30.0477, lng: 31.2622,
          desc: 'A labyrinthine medieval bazaar of lanterns, spices and silver. Haggle hard, then collapse into a mint tea at a backstreet café.',
          rating: 4.6, reviews: 511, price: PriceRange.budget, family: true,
          best: 'Evening', tags: const ['Market', 'Shopping', 'Lively'], likes: 360, saves: 290, ageDays: 60,
        ),
        _spot(
          id: 's_azhar_park', name: 'Al-Azhar Park', city: 'Cairo', country: 'Egypt',
          category: 'nature', lat: 30.0407, lng: 31.2625,
          desc: 'A green oasis with sweeping views over Islamic Cairo\'s minarets and the Citadel. Perfect for golden hour.',
          rating: 4.5, reviews: 233, price: PriceRange.budget, free: false, family: true,
          best: 'Sunset', tags: const ['Views', 'Relaxing', 'Family'], likes: 210, saves: 180, ageDays: 50,
        ),
        _spot(
          id: 's_abou_tarek', name: 'Koshary Abou Tarek', city: 'Cairo', country: 'Egypt',
          category: 'food', lat: 30.0524, lng: 31.2447,
          desc: 'The most famous koshary in the city — a comforting bowl of rice, lentils, pasta and crispy onions. Cheap, vegetarian, unforgettable.',
          rating: 4.7, reviews: 902, price: PriceRange.free, free: false, family: true,
          best: 'Lunch', tags: const ['Local favourite', 'Vegetarian', 'Cheap eats'], likes: 640, saves: 470, ageDays: 40,
        ),
        _spot(
          id: 's_fishawy', name: 'El Fishawy Café', city: 'Cairo', country: 'Egypt',
          category: 'cafe', lat: 30.0487, lng: 31.2618,
          desc: 'A 200-year-old café tucked in the bazaar, all mirrors and mint tea and shisha smoke. A literary haunt that feels frozen in time.',
          rating: 4.4, reviews: 188, price: PriceRange.budget, gem: true,
          best: 'Late evening', tags: const ['Hidden gem', 'Historic', 'Atmospheric'], likes: 150, saves: 240, ageDays: 35,
        ),
        _spot(
          id: 's_cairo_tower', name: 'Cairo Tower', city: 'Cairo', country: 'Egypt',
          category: 'viewpoint', lat: 30.0459, lng: 31.2243,
          desc: '187 metres above the city with a 360° view of the Nile threading through Cairo. Best as the sun drops and the lights come on.',
          rating: 4.3, reviews: 276, price: PriceRange.moderate,
          best: 'Sunset', tags: const ['Views', 'Romantic'], likes: 190, saves: 160, ageDays: 45,
        ),
        // ── Berlin ───────────────────────────────────────────────────────────
        _spot(
          id: 's_brandenburg', name: 'Brandenburg Gate', city: 'Berlin', country: 'Germany',
          category: 'landmark', lat: 52.5163, lng: 13.3777,
          desc: 'Berlin\'s neoclassical icon and a symbol of reunification. Stunning when floodlit at night and blissfully crowd-free at dawn.',
          rating: 4.8, reviews: 845, price: PriceRange.free, free: true, family: true,
          best: 'Early morning or night', tags: const ['Free', 'Iconic', 'History'], likes: 700, saves: 540, ageDays: 75,
        ),
        _spot(
          id: 's_museum_island', name: 'Museum Island', city: 'Berlin', country: 'Germany',
          category: 'museum', lat: 52.5169, lng: 13.4019,
          desc: 'A UNESCO ensemble of five world-class museums on a Spree island, from the Pergamon\'s ancient altars to the bust of Nefertiti.',
          rating: 4.7, reviews: 503, price: PriceRange.moderate, family: true,
          best: 'Thursday evenings', tags: const ['UNESCO', 'Art', 'Indoor'], likes: 410, saves: 380, ageDays: 65,
        ),
        _spot(
          id: 's_markthalle', name: 'Markthalle Neun', city: 'Berlin', country: 'Germany',
          category: 'food', lat: 52.5010, lng: 13.4318,
          desc: 'A restored 1891 market hall. Come on Street Food Thursday and graze your way around the world, one stall at a time.',
          rating: 4.6, reviews: 367, price: PriceRange.moderate, family: true,
          best: 'Thursday evening', tags: const ['Street food', 'Local favourite'], likes: 320, saves: 260, ageDays: 38,
        ),
        _spot(
          id: 's_tempelhof', name: 'Tempelhofer Feld', city: 'Berlin', country: 'Germany',
          category: 'nature', lat: 52.4730, lng: 13.4030,
          desc: 'A decommissioned airport turned vast public park. Cycle the runways, fly a kite, or join the urban gardeners at sunset.',
          rating: 4.7, reviews: 412, price: PriceRange.free, free: true, family: true,
          best: 'Sunset', tags: const ['Free', 'Unusual', 'Outdoors'], likes: 380, saves: 300, ageDays: 42,
        ),
        _spot(
          id: 's_klunkerkranich', name: 'Klunkerkranich', city: 'Berlin', country: 'Germany',
          category: 'nightlife', lat: 52.4799, lng: 13.4360,
          desc: 'A rooftop bar and garden hidden atop a shopping-centre car park in Neukölln. Sundowners, DJs and one of the best skyline views in the city.',
          rating: 4.5, reviews: 289, price: PriceRange.moderate, gem: true,
          best: 'Sunset to late', tags: const ['Hidden gem', 'Rooftop', 'Views'], likes: 340, saves: 410, ageDays: 30,
        ),
        // ── Paris ────────────────────────────────────────────────────────────
        _spot(
          id: 's_eiffel', name: 'Eiffel Tower', city: 'Paris', country: 'France',
          category: 'landmark', lat: 48.8584, lng: 2.2945,
          desc: 'The grande dame of Paris. Watch from the Champ de Mars as she sparkles for five minutes on the hour after dark.',
          rating: 4.8, reviews: 1530, price: PriceRange.moderate, family: true, featured: true,
          best: 'After dark', tags: const ['Iconic', 'Romantic'], likes: 1200, saves: 1340, ageDays: 78,
        ),
        _spot(
          id: 's_louvre', name: 'Musée du Louvre', city: 'Paris', country: 'France',
          category: 'museum', lat: 48.8606, lng: 2.3376,
          desc: 'The world\'s most-visited museum. Pick two or three wings, book ahead, and don\'t miss the courtyard pyramid at night.',
          rating: 4.7, reviews: 1102, price: PriceRange.moderate, family: true,
          best: 'Wednesday/Friday late', tags: const ['Art', 'Indoor', 'Must-see'], likes: 760, saves: 690, ageDays: 66,
        ),
        _spot(
          id: 's_marais_cafe', name: 'Café in Le Marais', city: 'Paris', country: 'France',
          category: 'cafe', lat: 48.8571, lng: 2.3625,
          desc: 'Cobbled lanes, vintage boutiques and the best falafel in the city. Grab a corner table and watch the most stylish street in Paris drift by.',
          rating: 4.5, reviews: 214, price: PriceRange.moderate, gem: true,
          best: 'Afternoon', tags: const ['Hidden gem', 'Coffee', 'Shopping'], likes: 230, saves: 280, ageDays: 28,
        ),
        _spot(
          id: 's_montmartre', name: 'Montmartre & Sacré-Cœur', city: 'Paris', country: 'France',
          category: 'viewpoint', lat: 48.8867, lng: 2.3431,
          desc: 'Climb the hill of artists to the white domes of Sacré-Cœur and the finest free view over Paris. Lose yourself in the lanes behind it.',
          rating: 4.6, reviews: 498, price: PriceRange.free, free: true, family: true,
          best: 'Sunset', tags: const ['Free', 'Views', 'Art'], likes: 520, saves: 470, ageDays: 33,
        ),
        // ── Rome ─────────────────────────────────────────────────────────────
        _spot(
          id: 's_colosseum', name: 'Colosseum', city: 'Rome', country: 'Italy',
          category: 'landmark', lat: 41.8902, lng: 12.4922,
          desc: 'The mighty amphitheatre of ancient Rome. Book a skip-the-line slot and add the underground tour to stand where gladiators waited.',
          rating: 4.8, reviews: 1340, price: PriceRange.moderate, family: true, featured: true,
          best: 'First slot of the day', tags: const ['UNESCO', 'History', 'Must-see'], likes: 990, saves: 1050, ageDays: 72,
        ),
        _spot(
          id: 's_trastevere', name: 'Trastevere', city: 'Rome', country: 'Italy',
          category: 'food', lat: 41.8896, lng: 12.4690,
          desc: 'Rome\'s most charming quarter — ivy-clad lanes, trattorias and piazzas that come alive after dark. The place for an unhurried Roman dinner.',
          rating: 4.7, reviews: 588, price: PriceRange.moderate, family: true,
          best: 'Evening', tags: const ['Food', 'Nightlife', 'Atmospheric'], likes: 540, saves: 600, ageDays: 31,
        ),
        _spot(
          id: 's_pantheon', name: 'Pantheon', city: 'Rome', country: 'Italy',
          category: 'historic', lat: 41.8986, lng: 12.4769,
          desc: 'A 2,000-year-old temple with the world\'s largest unreinforced concrete dome and an oculus open to the sky. Free, breathtaking, central.',
          rating: 4.8, reviews: 720, price: PriceRange.free, free: true, family: true,
          best: 'Late afternoon', tags: const ['Free', 'History', 'Architecture'], likes: 610, saves: 480, ageDays: 36,
        ),
        // ── Cairo (extra) ────────────────────────────────────────────────────
        _spot(
          id: 's_citadel', name: 'Salah El-Din Citadel', city: 'Cairo', country: 'Egypt',
          category: 'historic', lat: 30.0287, lng: 31.2599,
          desc: 'A medieval Islamic fortress crowned by the alabaster Mohamed Ali Mosque, with the whole city sprawling below.',
          rating: 4.6, reviews: 388, price: PriceRange.budget, family: true,
          best: 'Late afternoon', tags: const ['History', 'Views', 'Architecture'], likes: 300, saves: 240, ageDays: 58,
          by: 'u_omar', byName: 'Omar Farouk',
        ),
        _spot(
          id: 's_felucca', name: 'Nile Felucca Sunset Sail', city: 'Cairo', country: 'Egypt',
          category: 'adventure', lat: 30.0561, lng: 31.2284,
          desc: 'Hire a traditional wooden sailboat at golden hour and drift past Zamalek as the city lights flicker on.',
          rating: 4.7, reviews: 196, price: PriceRange.budget, gem: true,
          best: 'Sunset', tags: const ['Hidden gem', 'Romantic', 'Nile'], likes: 260, saves: 320, ageDays: 24,
          by: 'u_omar', byName: 'Omar Farouk',
        ),
        // ── Berlin (extra) ───────────────────────────────────────────────────
        _spot(
          id: 's_east_side', name: 'East Side Gallery', city: 'Berlin', country: 'Germany',
          category: 'art', lat: 52.5050, lng: 13.4399,
          desc: 'The longest surviving stretch of the Berlin Wall, now a 1.3km open-air gallery of murals — including the famous fraternal kiss.',
          rating: 4.6, reviews: 421, price: PriceRange.free, free: true, family: true,
          best: 'Morning', tags: const ['Free', 'Street art', 'History'], likes: 360, saves: 250, ageDays: 47,
        ),
        _spot(
          id: 's_reichstag', name: 'Reichstag Dome', city: 'Berlin', country: 'Germany',
          category: 'viewpoint', lat: 52.5186, lng: 13.3762,
          desc: 'Norman Foster\'s glass dome over the German parliament — free to visit with a booking, spiralling up to a 360° city panorama.',
          rating: 4.7, reviews: 512, price: PriceRange.free, free: true, family: true,
          best: 'Dusk', tags: const ['Free', 'Architecture', 'Views'], likes: 410, saves: 300, ageDays: 40,
        ),
        // ── Paris (extra) ────────────────────────────────────────────────────
        _spot(
          id: 's_orsay', name: 'Musée d\'Orsay', city: 'Paris', country: 'France',
          category: 'museum', lat: 48.8600, lng: 2.3266,
          desc: 'Impressionist heaven in a beaux-arts railway station — Monet, Van Gogh and Degas under a giant glass clock.',
          rating: 4.8, reviews: 640, price: PriceRange.moderate, family: true,
          best: 'Thursday late', tags: const ['Art', 'Indoor', 'Must-see'], likes: 520, saves: 430, ageDays: 35,
          by: 'u_sofia', byName: 'Sofia Lindqvist',
        ),
        _spot(
          id: 's_seine', name: 'Seine Riverbanks', city: 'Paris', country: 'France',
          category: 'nature', lat: 48.8566, lng: 2.3522,
          desc: 'Stroll the UNESCO-listed quays past bouquinistes and bridges; picnic by the water as the Eiffel Tower sparkles.',
          rating: 4.6, reviews: 287, price: PriceRange.free, free: true, family: true,
          best: 'Evening', tags: const ['Free', 'Romantic', 'Walk'], likes: 290, saves: 240, ageDays: 22,
          by: 'u_sofia', byName: 'Sofia Lindqvist',
        ),
        // ── Rome (extra) ─────────────────────────────────────────────────────
        _spot(
          id: 's_trevi', name: 'Trevi Fountain', city: 'Rome', country: 'Italy',
          category: 'landmark', lat: 41.9009, lng: 12.4833,
          desc: 'Rome\'s most theatrical baroque fountain. Toss a coin over your shoulder and you\'re destined to return.',
          rating: 4.7, reviews: 980, price: PriceRange.free, free: true, family: true,
          best: 'Early morning', tags: const ['Free', 'Iconic', 'Baroque'], likes: 720, saves: 560, ageDays: 50,
          by: 'u_marco', byName: 'Marco Bianchi',
        ),
        _spot(
          id: 's_vatican', name: 'Vatican Museums & Sistine Chapel', city: 'Rome', country: 'Italy',
          category: 'museum', lat: 41.9065, lng: 12.4536,
          desc: 'Mile after mile of treasures ending in Michelangelo\'s ceiling. Book the first slot or a Friday-night opening.',
          rating: 4.8, reviews: 1210, price: PriceRange.premium, family: true,
          best: 'First slot', tags: const ['Art', 'Must-see', 'Indoor'], likes: 880, saves: 760, ageDays: 44,
          by: 'u_marco', byName: 'Marco Bianchi',
        ),
        // ── London ───────────────────────────────────────────────────────────
        _spot(
          id: 's_tower_bridge', name: 'Tower Bridge', city: 'London', country: 'United Kingdom',
          category: 'landmark', lat: 51.5055, lng: -0.0754,
          desc: 'London\'s Victorian icon over the Thames. Walk the high-level glass floor and time it for a bridge lift.',
          rating: 4.7, reviews: 905, price: PriceRange.moderate, family: true, featured: true,
          best: 'Golden hour', tags: const ['Iconic', 'Views', 'Architecture'], likes: 700, saves: 540, ageDays: 52,
          by: 'u_emma', byName: 'Emma Clarke',
        ),
        _spot(
          id: 's_british_museum', name: 'The British Museum', city: 'London', country: 'United Kingdom',
          category: 'museum', lat: 51.5194, lng: -0.1270,
          desc: 'From the Rosetta Stone to the Parthenon marbles — two million years of history, and entry is free.',
          rating: 4.8, reviews: 1120, price: PriceRange.free, free: true, family: true,
          best: 'Weekday opening', tags: const ['Free', 'History', 'Must-see'], likes: 760, saves: 640, ageDays: 48,
          by: 'u_emma', byName: 'Emma Clarke',
        ),
        _spot(
          id: 's_borough', name: 'Borough Market', city: 'London', country: 'United Kingdom',
          category: 'food', lat: 51.5055, lng: -0.0905,
          desc: 'A 1,000-year-old food market under railway arches — artisan cheese, salt-beef bagels and sizzling street food.',
          rating: 4.6, reviews: 533, price: PriceRange.moderate, family: true,
          best: 'Late morning', tags: const ['Street food', 'Local favourite'], likes: 420, saves: 360, ageDays: 30,
          by: 'u_emma', byName: 'Emma Clarke',
        ),
        _spot(
          id: 's_sky_garden', name: 'Sky Garden', city: 'London', country: 'United Kingdom',
          category: 'viewpoint', lat: 51.5113, lng: -0.0838,
          desc: 'A free three-storey rooftop garden with floor-to-ceiling views across the City — book a slot in advance.',
          rating: 4.5, reviews: 388, price: PriceRange.free, free: true, gem: true,
          best: 'Sunset', tags: const ['Free', 'Hidden gem', 'Views'], likes: 330, saves: 410, ageDays: 26,
          by: 'u_emma', byName: 'Emma Clarke',
        ),
        _spot(
          id: 's_camden', name: 'Camden Market', city: 'London', country: 'United Kingdom',
          category: 'shopping', lat: 51.5414, lng: -0.1460,
          desc: 'Punk-spirited maze of stalls, vintage and global street eats along the canal in Camden Town.',
          rating: 4.4, reviews: 412, price: PriceRange.budget, family: true,
          best: 'Weekend', tags: const ['Market', 'Vintage', 'Lively'], likes: 280, saves: 220, ageDays: 21,
          by: 'u_emma', byName: 'Emma Clarke',
        ),
        // ── Barcelona ────────────────────────────────────────────────────────
        _spot(
          id: 's_sagrada', name: 'Sagrada Família', city: 'Barcelona', country: 'Spain',
          category: 'landmark', lat: 41.4036, lng: 2.1744,
          desc: 'Gaudí\'s still-unfinished basilica — a forest of stone columns lit by kaleidoscope stained glass. Book a timed ticket.',
          rating: 4.9, reviews: 1480, price: PriceRange.moderate, family: true, featured: true,
          best: 'Morning light', tags: const ['UNESCO', 'Architecture', 'Must-see'], likes: 1100, saves: 980, ageDays: 56,
          by: 'u_diego', byName: 'Diego Morales',
        ),
        _spot(
          id: 's_park_guell', name: 'Park Güell', city: 'Barcelona', country: 'Spain',
          category: 'nature', lat: 41.4145, lng: 2.1527,
          desc: 'Gaudí\'s mosaic dreamscape on a hill — the serpentine bench and terrace frame the whole city and sea.',
          rating: 4.6, reviews: 712, price: PriceRange.budget, family: true,
          best: 'Opening time', tags: const ['Architecture', 'Views', 'Park'], likes: 540, saves: 480, ageDays: 41,
          by: 'u_diego', byName: 'Diego Morales',
        ),
        _spot(
          id: 's_boqueria', name: 'Mercat de la Boqueria', city: 'Barcelona', country: 'Spain',
          category: 'food', lat: 41.3817, lng: 2.1716,
          desc: 'A riot of colour off La Rambla — jamón, fresh juices and tapas bars where locals grab breakfast at the counter.',
          rating: 4.5, reviews: 498, price: PriceRange.budget, family: true,
          best: 'Morning', tags: const ['Market', 'Tapas', 'Local favourite'], likes: 360, saves: 300, ageDays: 33,
          by: 'u_diego', byName: 'Diego Morales',
        ),
        _spot(
          id: 's_barceloneta', name: 'Barceloneta Beach', city: 'Barcelona', country: 'Spain',
          category: 'beach', lat: 41.3784, lng: 2.1925,
          desc: 'The city beach — golden sand, chiringuitos and a boardwalk made for sunset strolls and seafood paella.',
          rating: 4.3, reviews: 365, price: PriceRange.free, free: true, family: true,
          best: 'Late afternoon', tags: const ['Free', 'Beach', 'Seafood'], likes: 320, saves: 280, ageDays: 19,
          by: 'u_diego', byName: 'Diego Morales',
        ),
        _spot(
          id: 's_gothic', name: 'Gothic Quarter', city: 'Barcelona', country: 'Spain',
          category: 'historic', lat: 41.3839, lng: 2.1762,
          desc: 'Get lost in narrow medieval lanes, hidden plazas and the Roman walls at the heart of old Barcelona.',
          rating: 4.7, reviews: 421, price: PriceRange.free, free: true, gem: true,
          best: 'Evening', tags: const ['Free', 'Hidden gem', 'History'], likes: 300, saves: 260, ageDays: 28,
          by: 'u_diego', byName: 'Diego Morales',
        ),
        // ── Istanbul ─────────────────────────────────────────────────────────
        _spot(
          id: 's_hagia', name: 'Hagia Sophia', city: 'Istanbul', country: 'Türkiye',
          category: 'landmark', lat: 41.0086, lng: 28.9802,
          desc: 'Fifteen centuries of history under one colossal dome — Byzantine cathedral, Ottoman mosque, and breathtaking mosaics.',
          rating: 4.8, reviews: 1320, price: PriceRange.moderate, family: true, featured: true,
          best: 'Early morning', tags: const ['UNESCO', 'History', 'Architecture'], likes: 940, saves: 820, ageDays: 49,
        ),
        _spot(
          id: 's_blue_mosque', name: 'Blue Mosque', city: 'Istanbul', country: 'Türkiye',
          category: 'landmark', lat: 41.0054, lng: 28.9768,
          desc: 'The Sultan Ahmed Mosque, ringed by six minarets and lined with 20,000 hand-painted İznik tiles. Free to enter outside prayer.',
          rating: 4.7, reviews: 870, price: PriceRange.free, free: true, family: true,
          best: 'Mid-morning', tags: const ['Free', 'Architecture', 'History'], likes: 600, saves: 480, ageDays: 43,
        ),
        _spot(
          id: 's_grand_bazaar', name: 'Grand Bazaar', city: 'Istanbul', country: 'Türkiye',
          category: 'shopping', lat: 41.0106, lng: 28.9680,
          desc: 'One of the world\'s oldest covered markets — 4,000 shops of lanterns, carpets, spices and gold. Haggling expected.',
          rating: 4.5, reviews: 640, price: PriceRange.budget, family: true,
          best: 'Late morning', tags: const ['Market', 'Shopping', 'Lively'], likes: 410, saves: 330, ageDays: 36,
        ),
        _spot(
          id: 's_galata', name: 'Galata Tower', city: 'Istanbul', country: 'Türkiye',
          category: 'viewpoint', lat: 41.0256, lng: 28.9744,
          desc: 'A medieval stone tower with a panoramic balcony over the Golden Horn, the Bosphorus and the old city rooftops.',
          rating: 4.4, reviews: 388, price: PriceRange.moderate,
          best: 'Sunset', tags: const ['Views', 'History'], likes: 280, saves: 240, ageDays: 25,
        ),
        _spot(
          id: 's_ortakoy', name: 'Ortaköy Waterfront', city: 'Istanbul', country: 'Türkiye',
          category: 'food', lat: 41.0473, lng: 29.0269,
          desc: 'A buzzy Bosphorus square under the bridge — grab a stuffed kumpir potato and watch the ferries glide by.',
          rating: 4.5, reviews: 254, price: PriceRange.budget, gem: true,
          best: 'Evening', tags: const ['Hidden gem', 'Street food', 'Waterfront'], likes: 220, saves: 260, ageDays: 17,
        ),
        // ── Amsterdam ────────────────────────────────────────────────────────
        _spot(
          id: 's_rijks', name: 'Rijksmuseum', city: 'Amsterdam', country: 'Netherlands',
          category: 'museum', lat: 52.3600, lng: 4.8852,
          desc: 'The Dutch Golden Age in one grand building — Rembrandt\'s Night Watch and Vermeer\'s quiet masterpieces.',
          rating: 4.8, reviews: 690, price: PriceRange.moderate, family: true,
          best: 'Opening time', tags: const ['Art', 'Indoor', 'Must-see'], likes: 480, saves: 400, ageDays: 38,
        ),
        _spot(
          id: 's_vondel', name: 'Vondelpark', city: 'Amsterdam', country: 'Netherlands',
          category: 'nature', lat: 52.3580, lng: 4.8686,
          desc: 'Amsterdam\'s green living room — cycle the loops, picnic on the lawns and catch free summer concerts.',
          rating: 4.6, reviews: 312, price: PriceRange.free, free: true, family: true,
          best: 'Afternoon', tags: const ['Free', 'Park', 'Cycling'], likes: 250, saves: 200, ageDays: 23,
        ),
        _spot(
          id: 's_jordaan', name: 'Jordaan Canals', city: 'Amsterdam', country: 'Netherlands',
          category: 'historic', lat: 52.3740, lng: 4.8830,
          desc: 'The prettiest quarter — gabled houses, flower-lined bridges and cosy brown cafés down every lane.',
          rating: 4.7, reviews: 276, price: PriceRange.free, free: true, gem: true,
          best: 'Golden hour', tags: const ['Free', 'Hidden gem', 'Canals'], likes: 240, saves: 230, ageDays: 20,
        ),
        // ── Tokyo ────────────────────────────────────────────────────────────
        _spot(
          id: 's_sensoji', name: 'Sensō-ji Temple', city: 'Tokyo', country: 'Japan',
          category: 'historic', lat: 35.7148, lng: 139.7967,
          desc: 'Tokyo\'s oldest temple, reached through the giant Kaminarimon lantern and a street of traditional snack stalls.',
          rating: 4.7, reviews: 980, price: PriceRange.free, free: true, family: true, featured: true,
          best: 'Early morning', tags: const ['Free', 'History', 'Culture'], likes: 720, saves: 560, ageDays: 47,
          by: 'u_yuki', byName: 'Yuki Tanaka',
        ),
        _spot(
          id: 's_shibuya', name: 'Shibuya Crossing', city: 'Tokyo', country: 'Japan',
          category: 'landmark', lat: 35.6595, lng: 139.7004,
          desc: 'The world\'s busiest pedestrian scramble. Watch the wave from the Starbucks window, then dive into the neon.',
          rating: 4.5, reviews: 760, price: PriceRange.free, free: true,
          best: 'After dark', tags: const ['Free', 'Iconic', 'Nightlife'], likes: 520, saves: 380, ageDays: 31,
          by: 'u_yuki', byName: 'Yuki Tanaka',
        ),
        _spot(
          id: 's_tsukiji', name: 'Tsukiji Outer Market', city: 'Tokyo', country: 'Japan',
          category: 'food', lat: 35.6654, lng: 139.7707,
          desc: 'Go early and graze: the freshest sushi, tamagoyaki on a stick and grilled scallops from market stalls.',
          rating: 4.6, reviews: 540, price: PriceRange.budget, family: true,
          best: 'Early morning', tags: const ['Street food', 'Sushi', 'Local favourite'], likes: 430, saves: 360, ageDays: 27,
          by: 'u_yuki', byName: 'Yuki Tanaka',
        ),
        _spot(
          id: 's_teamlab', name: 'teamLab Planets', city: 'Tokyo', country: 'Japan',
          category: 'art', lat: 35.6256, lng: 139.7836,
          desc: 'Wade barefoot through water and infinite mirrored light in this immersive digital-art museum. Book ahead.',
          rating: 4.7, reviews: 612, price: PriceRange.moderate, gem: true,
          best: 'Weekday', tags: const ['Hidden gem', 'Immersive', 'Art'], likes: 480, saves: 520, ageDays: 18,
          by: 'u_yuki', byName: 'Yuki Tanaka',
        ),
        // ── New York ─────────────────────────────────────────────────────────
        _spot(
          id: 's_central_park', name: 'Central Park', city: 'New York', country: 'United States',
          category: 'nature', lat: 40.7829, lng: -73.9654,
          desc: '843 acres of lawns, lakes and skyline. Rent a rowboat at the Loeb Boathouse or just wander Bethesda Terrace.',
          rating: 4.8, reviews: 1340, price: PriceRange.free, free: true, family: true, featured: true,
          best: 'Morning', tags: const ['Free', 'Park', 'Iconic'], likes: 980, saves: 720, ageDays: 53,
        ),
        _spot(
          id: 's_top_rock', name: 'Top of the Rock', city: 'New York', country: 'United States',
          category: 'viewpoint', lat: 40.7593, lng: -73.9794,
          desc: 'The best skyline view in the city — because this is the one that actually includes the Empire State Building.',
          rating: 4.7, reviews: 870, price: PriceRange.premium, family: true,
          best: 'Sunset', tags: const ['Views', 'Iconic', 'Romantic'], likes: 600, saves: 520, ageDays: 39,
        ),
        _spot(
          id: 's_met', name: 'The Met', city: 'New York', country: 'United States',
          category: 'museum', lat: 40.7794, lng: -73.9632,
          desc: 'Two million works from Egyptian temples to Rooftop sculpture — one of the great museums of the world.',
          rating: 4.8, reviews: 720, price: PriceRange.moderate, family: true,
          best: 'Weekday', tags: const ['Art', 'Indoor', 'Must-see'], likes: 500, saves: 420, ageDays: 34,
        ),
        _spot(
          id: 's_brooklyn_bridge', name: 'Brooklyn Bridge', city: 'New York', country: 'United States',
          category: 'landmark', lat: 40.7061, lng: -73.9969,
          desc: 'Walk the wooden promenade from Manhattan to DUMBO at dawn for the gothic arches and a clean shot of the skyline.',
          rating: 4.7, reviews: 910, price: PriceRange.free, free: true, family: true,
          best: 'Sunrise', tags: const ['Free', 'Iconic', 'Walk'], likes: 640, saves: 480, ageDays: 29,
        ),
        // ── Dubai ────────────────────────────────────────────────────────────
        _spot(
          id: 's_burj', name: 'Burj Khalifa — At the Top', city: 'Dubai', country: 'United Arab Emirates',
          category: 'viewpoint', lat: 25.1972, lng: 55.2744,
          desc: 'The world\'s tallest building. Ride to the 124th-floor deck for sunset, then watch the fountain show below.',
          rating: 4.7, reviews: 1180, price: PriceRange.premium, family: true, featured: true,
          best: 'Sunset', tags: const ['Iconic', 'Views', 'Architecture'], likes: 860, saves: 700, ageDays: 46,
        ),
        _spot(
          id: 's_dubai_mall', name: 'The Dubai Mall', city: 'Dubai', country: 'United Arab Emirates',
          category: 'shopping', lat: 25.1985, lng: 55.2796,
          desc: 'Beyond shopping: an aquarium, an indoor waterfall and the dancing Dubai Fountain right outside.',
          rating: 4.6, reviews: 760, price: PriceRange.moderate, family: true,
          best: 'Evening', tags: const ['Shopping', 'Family', 'Indoor'], likes: 430, saves: 360, ageDays: 26,
        ),
        _spot(
          id: 's_jumeirah', name: 'Jumeirah Public Beach', city: 'Dubai', country: 'United Arab Emirates',
          category: 'beach', lat: 25.2048, lng: 55.2708,
          desc: 'Soft white sand with a postcard view of the sail-shaped Burj Al Arab — free, with showers and cafés nearby.',
          rating: 4.5, reviews: 412, price: PriceRange.free, free: true, family: true,
          best: 'Late afternoon', tags: const ['Free', 'Beach', 'Views'], likes: 340, saves: 300, ageDays: 22,
        ),
        // ── Lisbon ───────────────────────────────────────────────────────────
        _spot(
          id: 's_belem', name: 'Belém Tower', city: 'Lisbon', country: 'Portugal',
          category: 'landmark', lat: 38.6916, lng: -9.2160,
          desc: 'A jewel-box fortress on the Tagus from the Age of Discovery — pair it with a warm pastel de nata nearby.',
          rating: 4.6, reviews: 498, price: PriceRange.budget, family: true,
          best: 'Morning', tags: const ['UNESCO', 'History', 'Riverside'], likes: 360, saves: 290, ageDays: 32,
        ),
        _spot(
          id: 's_alfama', name: 'Alfama & Miradouro', city: 'Lisbon', country: 'Portugal',
          category: 'viewpoint', lat: 38.7118, lng: -9.1300,
          desc: 'Tangled medieval lanes climbing to terrace viewpoints where fado drifts out of tiny taverns at night.',
          rating: 4.7, reviews: 364, price: PriceRange.free, free: true, gem: true,
          best: 'Sunset', tags: const ['Free', 'Hidden gem', 'Views'], likes: 300, saves: 280, ageDays: 21,
        ),
        _spot(
          id: 's_timeout', name: 'Time Out Market', city: 'Lisbon', country: 'Portugal',
          category: 'food', lat: 38.7077, lng: -9.1459,
          desc: 'The city\'s best chefs under one roof — order from a dozen stalls and share at the long communal tables.',
          rating: 4.5, reviews: 421, price: PriceRange.moderate, family: true,
          best: 'Early dinner', tags: const ['Food hall', 'Local favourite'], likes: 330, saves: 260, ageDays: 16,
        ),
        // ── Pending (populate the admin moderation queue) ─────────────────────
        _spot(
          id: 's_pending_sequoia', name: 'Sequoia Nile Lounge', city: 'Cairo', country: 'Egypt',
          category: 'food', lat: 30.0726, lng: 31.2228,
          desc: 'A breezy riverside lounge on the tip of Zamalek with shisha and a view of the water. Submitted for review.',
          rating: 0, reviews: 0, price: PriceRange.premium, gem: true,
          best: 'Evening', tags: const ['Nile view', 'Lounge'], status: SpotStatus.pending, verified: false, ageDays: 2,
        ),
        _spot(
          id: 's_pending_teufelsberg', name: 'Teufelsberg', city: 'Berlin', country: 'Germany',
          category: 'adventure', lat: 52.4979, lng: 13.2410,
          desc: 'An abandoned Cold-War listening station on an artificial hill, now covered in street art. Submitted for review.',
          rating: 0, reviews: 0, price: PriceRange.budget, gem: true,
          best: 'Daytime', tags: const ['Street art', 'Urbex', 'Views'], status: SpotStatus.pending, verified: false, ageDays: 1,
        ),
        _spot(
          id: 's_pending_sky_bar', name: 'Leblon Rooftop Bar', city: 'London', country: 'United Kingdom',
          category: 'nightlife', lat: 51.5129, lng: -0.0890,
          desc: 'A new speakeasy-style rooftop with skyline cocktails near the Gherkin. Submitted for review.',
          rating: 0, reviews: 0, price: PriceRange.premium,
          best: 'Late evening', tags: const ['Rooftop', 'Cocktails'], status: SpotStatus.pending, verified: false, ageDays: 1,
          by: 'u_emma', byName: 'Emma Clarke',
        ),
        _spot(
          id: 's_pending_ramen', name: 'Ichiban Ramen Bar', city: 'Tokyo', country: 'Japan',
          category: 'food', lat: 35.6938, lng: 139.7034,
          desc: 'A tiny 8-seat counter doing rich tonkotsu ramen in Shinjuku\'s back alleys. Submitted for review.',
          rating: 0, reviews: 0, price: PriceRange.budget, gem: true,
          best: 'Late night', tags: const ['Ramen', 'Hidden gem'], status: SpotStatus.pending, verified: false, ageDays: 3,
          by: 'u_yuki', byName: 'Yuki Tanaka',
        ),
      ];

  static Review _review(String id, String spotId, String name, double rating, String comment, int days, {String avatar = ''}) {
    return Review(
      id: id,
      spotId: spotId,
      userId: 'u_$name'.toLowerCase(),
      userName: name,
      userPhoto: avatar.isEmpty ? photo('avatar-$id') : avatar,
      rating: rating,
      comment: comment,
      createdAt: _daysAgo(days),
    );
  }

  static List<Review> reviews() => [
        _review('r1', 's_pyramids', 'James', 5.0, 'Got there for opening and had the desert almost to myself. Unreal. Negotiate your camel ride price up front!', 6),
        _review('r2', 's_pyramids', 'Aisha', 4.5, 'Bigger than you can imagine. Bring water and a hat — there is zero shade.', 14),
        _review('r3', 's_abou_tarek', 'Lukas', 5.0, 'Best 40 EGP I spent in Egypt. The garlic-vinegar sauce makes it.', 4),
        _review('r4', 's_klunkerkranich', 'Sofia', 4.5, 'Sunset here is magic. Go early on weekends or you will queue for the lift.', 9),
        _review('r5', 's_trastevere', 'Marco', 5.0, 'Wandered without a plan and ate the best cacio e pepe of my life. Pure Rome.', 11),
        _review('r6', 's_brandenburg', 'Maya', 4.5, 'Came at 6am for photos with nobody around — completely worth the early alarm.', 20),
        _review('r7', 's_montmartre', 'Chloé', 4.5, 'Skip the funicular and walk up through the back lanes. Quieter and prettier.', 16),
        _review('r8', 's_fishawy', 'Omar', 4.0, 'Touristy now but still atmospheric. Order the mint tea and just soak it in.', 8),
        _review('r9', 's_sagrada', 'Emma', 5.0, 'No photo prepares you for the light inside at mid-morning. Book the towers too.', 5),
        _review('r10', 's_sagrada', 'Yuki', 4.5, 'Stunning, but go with a timed ticket or you will wait an hour.', 12),
        _review('r11', 's_hagia', 'Diego', 5.0, 'Standing under that dome is humbling. Came at opening and nearly had it to myself.', 7),
        _review('r12', 's_central_park', 'Maya', 4.5, 'Rented a rowboat on the lake at golden hour — pure magic with the skyline behind.', 9),
        _review('r13', 's_tower_bridge', 'Marco', 4.0, 'The glass floor walkway is a fun touch. Time it for a bridge lift if you can.', 15),
        _review('r14', 's_british_museum', 'Lukas', 5.0, 'Free, vast, and the Egyptian rooms are unreal. Give it a full morning.', 6),
        _review('r15', 's_sky_garden', 'Sofia', 4.5, 'Free rooftop with a cocktail in hand — book ahead, slots vanish fast.', 4),
        _review('r16', 's_sensoji', 'Emma', 4.5, 'Go before 8am for empty photos, then snack your way down Nakamise street.', 10),
        _review('r17', 's_teamlab', 'Diego', 5.0, 'Roll up your trousers — you walk through water and light. Unlike anything else.', 3),
        _review('r18', 's_tsukiji', 'Chloé', 5.0, 'Best tamago and scallops of my life, all before 9am. Bring cash.', 8),
        _review('r19', 's_burj', 'James', 4.5, 'Sunset slot is worth the premium. The fountain show afterwards is the bonus.', 11),
        _review('r20', 's_park_guell', 'Aisha', 4.0, 'Beautiful but busy — first entry slot is the move. The view over the city is huge.', 13),
        _review('r21', 's_trevi', 'Yuki', 4.5, 'Came at 6:30am and had the fountain almost alone. By 10am it is a wall of people.', 7),
        _review('r22', 's_borough', 'Marco', 4.5, 'Grazed my way through cheese, a salt-beef bagel and a brownie. No regrets.', 5),
        _review('r23', 's_reichstag', 'Maya', 5.0, 'Free, and the spiral up the glass dome at dusk is gorgeous. Just register ahead.', 14),
        _review('r24', 's_alfama', 'Diego', 4.5, 'Got lost on purpose and stumbled into fado drifting from a tiny tavern. Lisbon at its best.', 6),
        _review('r25', 's_brooklyn_bridge', 'Emma', 4.5, 'Walk it at sunrise from the Brooklyn side — empty, golden, and that skyline.', 9),
        _review('r26', 's_vatican', 'Lukas', 4.0, 'Overwhelming in the best way. Book the first slot or you are shuffling in a crowd.', 16),
        _review('r27', 's_ortakoy', 'Omar', 4.5, 'Loaded kumpir potato by the water under the bridge — cheap, huge, delicious.', 4),
        _review('r28', 's_felucca', 'Sofia', 5.0, 'Sailing the Nile as the lights came on was the highlight of Cairo for me.', 8),
      ];

  static List<Trip> trips() {
    final start = DateTime.now().add(const Duration(days: 21));
    final spotById = {for (final s in spots()) s.id: s};
    TripStop stop(String spotId, String name, String cat, double lat, double lng, DayPart part, String time, String note) {
      final s = spotById[spotId];
      return TripStop(
        spotId: spotId,
        name: name,
        photo: photo('$spotId-1'),
        categoryId: cat,
        lat: lat,
        lng: lng,
        dayPart: part,
        suggestedTime: time,
        note: note,
        estimatedCost: s != null ? TripEstimator.stopCost(s) : 0,
        durationMinutes: TripEstimator.durationMinutes(cat),
      );
    }

    final cairo = Trip(
        id: 't_cairo_demo',
        userId: 'u_traveller',
        destination: 'Cairo',
        country: 'Egypt',
        lat: 30.0444,
        lng: 31.2357,
        startDate: start,
        endDate: start.add(const Duration(days: 2)),
        aiGenerated: true,
        coverPhoto: photo('s_pyramids-1'),
        notes: 'Generated by SpotWise AI · history, food and views.',
        createdAt: _daysAgo(3),
        days: [
          TripDay(
            dayNumber: 1,
            date: start,
            title: 'Ancient wonders',
            summary: 'Start at the Pyramids before the heat, then dive into the city\'s treasures.',
            stops: [
              stop('s_pyramids', 'Pyramids of Giza', 'landmark', 29.9792, 31.1342, DayPart.morning, '08:00', 'Arrive at opening; book a camel ride to the panorama point.'),
              stop('s_egyptian_museum', 'The Egyptian Museum', 'museum', 30.0478, 31.2336, DayPart.afternoon, '13:30', 'See Tutankhamun\'s gallery first.'),
              stop('s_cairo_tower', 'Cairo Tower', 'viewpoint', 30.0459, 31.2243, DayPart.evening, '18:00', 'Sunset over the Nile.'),
            ],
          ),
          TripDay(
            dayNumber: 2,
            date: start.add(const Duration(days: 1)),
            title: 'Islamic Cairo',
            summary: 'Bazaars, tea houses and a green oasis.',
            stops: [
              stop('s_khan', 'Khan el-Khalili', 'shopping', 30.0477, 31.2622, DayPart.morning, '10:00', 'Haggle for lanterns and spices.'),
              stop('s_fishawy', 'El Fishawy Café', 'cafe', 30.0487, 31.2618, DayPart.afternoon, '13:00', 'Mint tea in the 200-year-old café.'),
              stop('s_azhar_park', 'Al-Azhar Park', 'nature', 30.0407, 31.2625, DayPart.evening, '17:30', 'Golden hour over the minarets.'),
            ],
          ),
          TripDay(
            dayNumber: 3,
            date: start.add(const Duration(days: 2)),
            title: 'Flavours of Cairo',
            summary: 'A relaxed final day built around food.',
            stops: [
              stop('s_abou_tarek', 'Koshary Abou Tarek', 'food', 30.0524, 31.2447, DayPart.afternoon, '13:00', 'The city\'s most famous koshary.'),
            ],
          ),
        ],
    );

    final romeStart = start.add(const Duration(days: 40));
    final rome = Trip(
      id: 't_rome_demo',
      userId: 'u_traveller',
      destination: 'Rome',
      country: 'Italy',
      lat: 41.8902,
      lng: 12.4922,
      startDate: romeStart,
      endDate: romeStart.add(const Duration(days: 1)),
      aiGenerated: true,
      coverPhoto: photo('s_colosseum-1'),
      notes: 'A weekend of ancient Rome, art and long dinners.',
      createdAt: _daysAgo(2),
      days: [
        TripDay(
          dayNumber: 1,
          date: romeStart,
          title: 'Ancient Rome',
          summary: 'Gladiators, a 2,000-year-old dome, and a coin in the Trevi.',
          stops: [
            stop('s_colosseum', 'Colosseum', 'landmark', 41.8902, 12.4922, DayPart.morning, '09:00', 'Book the first slot and add the underground tour.'),
            stop('s_pantheon', 'Pantheon', 'historic', 41.8986, 12.4769, DayPart.afternoon, '13:30', 'Free and breathtaking — look up at the oculus.'),
            stop('s_trevi', 'Trevi Fountain', 'landmark', 41.9009, 12.4833, DayPart.evening, '18:00', 'Toss a coin over your shoulder at dusk.'),
          ],
        ),
        TripDay(
          dayNumber: 2,
          date: romeStart.add(const Duration(days: 1)),
          title: 'Art & flavours',
          summary: 'Michelangelo in the morning, Trastevere by night.',
          stops: [
            stop('s_vatican', 'Vatican Museums', 'museum', 41.9065, 12.4536, DayPart.morning, '08:30', 'First slot beats the crowds to the Sistine Chapel.'),
            stop('s_trastevere', 'Trastevere', 'food', 41.8896, 12.4690, DayPart.evening, '19:30', 'Dinner in Rome\'s prettiest quarter.'),
          ],
        ),
      ],
    );

    return [
      cairo.copyWith(estimatedCost: TripEstimator.total(cairo.days)),
      rome.copyWith(estimatedCost: TripEstimator.total(rome.days)),
    ];
  }

  static List<NotificationItem> notifications() => [
        NotificationItem(
          id: 'n1', userId: 'u_traveller', title: 'Welcome to SpotWise 👋',
          body: 'Search a city, explore the map and let the AI plan your trip.',
          type: NotificationType.system, isRead: false, createdAt: _daysAgo(0),
        ),
        NotificationItem(
          id: 'n2', userId: 'u_traveller', title: 'Trip reminder',
          body: 'Your Cairo trip starts in 3 weeks — review your day 1 plan.',
          type: NotificationType.tripReminder, isRead: false, spotId: 's_pyramids', createdAt: _daysAgo(1),
        ),
        NotificationItem(
          id: 'n3', userId: 'u_traveller', title: 'Someone liked a spot you saved',
          body: 'Klunkerkranich is trending in Berlin this week.',
          type: NotificationType.like, isRead: true, spotId: 's_klunkerkranich', createdAt: _daysAgo(2),
        ),
        NotificationItem(
          id: 'n4', userId: 'u_admin', title: '2 spots awaiting review',
          body: 'New community submissions need moderation.',
          type: NotificationType.system, isRead: false, createdAt: _daysAgo(0),
        ),
      ];
}
