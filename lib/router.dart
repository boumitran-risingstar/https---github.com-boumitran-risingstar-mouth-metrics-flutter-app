import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/home_screen.dart';
import 'package:mouth_metrics/landing_page.dart';
import 'package:mouth_metrics/login_screen.dart';
import 'package:mouth_metrics/profile_screen.dart';
// Use a prefixed import to avoid name collisions
import 'package:mouth_metrics/screens/my_profile_screen.dart' as my_profile;

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
          path: 'my-profile',
          builder: (context, state) {
            // Use the prefixed class name
            return const my_profile.MyProfileScreen();
          },
        ),
      ],
    ),
  ],
);
