/// Named-route constants. Keeps route strings in one place and typo-free.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main shell
  static const String home = '/home';

  // Spots
  static const String spotDetails = '/spot';
  static const String addSpot = '/add-spot';
  static const String addReview = '/add-review';

  // Discovery
  static const String search = '/search';

  // Saved
  static const String favorites = '/favorites';

  // Trips
  static const String tripDetails = '/trip';
  static const String createTrip = '/create-trip';

  // AI
  static const String aiPlanner = '/ai-planner';
  static const String itineraryResult = '/itinerary';

  // Notifications
  static const String notifications = '/notifications';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminPending = '/admin/pending';
  static const String adminReports = '/admin/reports';
  static const String adminCategories = '/admin/categories';

  // Profile / settings
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String integrations = '/integrations';

  // Bonus
  static const String chat = '/chat';
}
