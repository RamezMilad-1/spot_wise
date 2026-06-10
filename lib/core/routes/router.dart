import 'package:flutter/material.dart';

import '../../models/spot.dart';
import '../../models/trip.dart';
import '../../screens/admin/admin_categories_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_pending_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../screens/ai/itinerary_result_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/chat/chat_placeholder_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/integrations/integrations_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/admin/admin_spots_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/shell/home_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/spots/add_review_screen.dart';
import '../../screens/spots/add_spot_screen.dart';
import '../../screens/spots/my_spots_screen.dart';
import '../../screens/spots/spot_details_screen.dart';
import '../../screens/trips/create_trip_screen.dart';
import '../../screens/trips/trip_details_screen.dart';
import 'app_routes.dart';

/// Central route table. Screens are pushed by name; arguments are typed here.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page = switch (settings.name) {
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.onboarding => const OnboardingScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      AppRoutes.home => const HomeShell(),
      AppRoutes.search => const SearchScreen(),
      AppRoutes.spotDetails => SpotDetailsScreen(spot: args as Spot),
      AppRoutes.addSpot => const AddSpotScreen(),
      AppRoutes.editSpot => AddSpotScreen(existing: args as Spot),
      AppRoutes.mySpots => const MySpotsScreen(),
      AppRoutes.addReview => AddReviewScreen(spot: args as Spot),
      AppRoutes.favorites => const FavoritesScreen(),
      AppRoutes.tripDetails => TripDetailsScreen(trip: args as Trip),
      AppRoutes.createTrip => CreateTripScreen(seedSpot: args as Spot?),
      AppRoutes.itineraryResult => ItineraryResultScreen(trip: args as Trip),
      AppRoutes.notifications => const NotificationsScreen(),
      AppRoutes.adminDashboard => const AdminDashboardScreen(),
      AppRoutes.adminPending => const AdminPendingScreen(),
      AppRoutes.adminReports => const AdminReportsScreen(),
      AppRoutes.adminCategories => const AdminCategoriesScreen(),
      AppRoutes.adminSpots => const AdminSpotsScreen(),
      AppRoutes.adminUsers => const AdminUsersScreen(),
      AppRoutes.profile => const ProfileScreen(),
      AppRoutes.editProfile => const EditProfileScreen(),
      AppRoutes.settings => const SettingsScreen(),
      AppRoutes.integrations => const IntegrationsScreen(),
      AppRoutes.chat => const ChatPlaceholderScreen(),
      _ => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Route not found: ${settings.name}')),
      ),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
