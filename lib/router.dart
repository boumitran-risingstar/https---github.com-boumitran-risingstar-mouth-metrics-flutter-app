import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/find_specialists_screen.dart';
import 'package:mouth_metrics/home_screen.dart';
import 'package:mouth_metrics/landing_page.dart';
import 'package:mouth_metrics/login_screen.dart';
import 'package:mouth_metrics/profile_screen.dart';
import 'package:mouth_metrics/nearby_clinics_screen.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const LandingPage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'login',
          builder: (context, state) {
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: 'home',
          builder: (context, state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) {
            return const ProfileScreen();
          },
        ),
        GoRoute(
          path: 'profile/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            return ProfileScreen(slug: slug);
          },
        ),
        GoRoute(
          path: 'nearby-clinics',
          builder: (context, state) {
            return const NearbyClinicsScreen();
          },
        ),
        GoRoute(
          path: 'find-specialists',
          builder: (context, state) {
            return const FindSpecialistsScreen();
          },
        ),
      ],
    ),
  ],
);
