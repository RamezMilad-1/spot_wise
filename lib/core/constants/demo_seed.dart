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
      submittedBy: 'u_contributor',
      submittedByName: 'Karim Hassan',
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
    return [cairo.copyWith(estimatedCost: TripEstimator.total(cairo.days))];
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
