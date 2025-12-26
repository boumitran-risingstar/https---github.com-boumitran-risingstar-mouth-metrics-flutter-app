
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mouth_metrics/business_profile_screen.dart';
import 'package:mouth_metrics/find_specialists_screen.dart';
import 'package:mouth_metrics/home_screen.dart';
import 'package:mouth_metrics/landing_page.dart';
import 'package:mouth_metrics/login_screen.dart';
import 'package:mouth_metrics/models/article_model.dart';
import 'package:mouth_metrics/my_businesses_screen.dart';
import 'package:mouth_metrics/profile_screen.dart';
import 'package:mouth_metrics/nearby_clinics_screen.dart';
import 'package:mouth_metrics/screens/article_list_screen.dart';
import 'package:mouth_metrics/screens/create_article_screen.dart';
import 'package:mouth_metrics/screens/article_detail_screen.dart';

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
        GoRoute(
          path: 'business-profile',
          builder: (context, state) {
            final businessId = state.uri.queryParameters['businessId'];
            return BusinessProfileScreen(businessId: businessId);
          },
        ),
        GoRoute(
          path: 'my-businesses',
          builder: (context, state) {
            return const MyBusinessesScreen();
          },
        ),
        GoRoute(
          path: 'articles',
          builder: (context, state) {
            return const ArticleListScreen();
          },
        ),
        GoRoute(
          path: 'create-article',
          builder: (context, state) {
            final article = state.extra as Article?;
            return CreateArticleScreen(article: article);
          },
        ),
        GoRoute(
            path: 'articles/:id',
            builder: (context, state) {
              final articleId = state.pathParameters['id']!;
              return ArticleDetailScreen(articleId: articleId);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final article = state.extra as Article?;
                  if (article == null) {
                    return const Scaffold(
                        body: Center(
                            child: Text(
                                'Error: Article not found for editing.')));
                  }
                  return CreateArticleScreen(article: article);
                },
              )
            ]),
      ],
    ),
  ],
);
