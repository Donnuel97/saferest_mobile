import 'package:flutter/material.dart';
import 'package:saferest_mobile/screens/login/login.dart'; // Import the login screen
import 'package:saferest_mobile/screens/registration/register.dart'; // Import the register screen
import 'package:saferest_mobile/screens/new_trips/trip_nav.dart';
import 'package:saferest_mobile/screens/dashboard/trips_list.dart';
import '../screens/dashboard/privacy_policy_page.dart';
import '../screens/dashboard/terms_conditions_page.dart';
import '../screens/navigation/nav.dart';
import 'package:saferest_mobile/screens/splash/splash.dart';


class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String new_trip = '/new_trip';
  static const String trips_list = '/trips_list';
  static const String splash = '/splash';
  static const String terms = '/terms'; // Add terms and conditions route
  static const String privacy = '/privacy'; // Add privacy policy route

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) => const MainNavigationScreen(),
    new_trip: (context) => const NewTripPage(),
    trips_list: (context) => const TripListPage(),
    splash: (context) => const SplashScreen(),
    terms: (context) => const TermsAndConditionsPage(), // Add terms and conditions screen
    privacy: (context) => const PrivacyPolicyPage(), // Add privacy policy screen
  };
}
