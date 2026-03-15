import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/user_search_screen.dart';
import 'screens/user_public_profile_screen.dart';
import 'screens/friend_requests_screen.dart';
import 'screens/anime_search_screen.dart';

/// Root widget for the Anime Recommendation app.
class AnimeRecommendationApp extends StatefulWidget {
  const AnimeRecommendationApp({super.key});

  @override
  State<AnimeRecommendationApp> createState() => _AnimeRecommendationAppState();
}

class _AnimeRecommendationAppState extends State<AnimeRecommendationApp> {
  final AuthService _authService = AuthService.instance;

  @override
  void initState() {
    super.initState();
    _authService.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Recommendations',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.grey[50],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 3,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(width: 1.2),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      home: ValueListenableBuilder<bool>(
        valueListenable: _authService.isReady,
        builder: (context, ready, child) {
          if (!ready) {
            return const LoadingScreen();
          }

          return ValueListenableBuilder<bool>(
            valueListenable: _authService.isLoggedInNotifier,
            builder: (context, isLoggedIn, child) {
              if (!isLoggedIn) {
                return const LoginScreen();
              }

              return ValueListenableBuilder<bool>(
                valueListenable: _authService.preferencesCompleteNotifier,
                builder: (context, preferencesComplete, child) {
                  if (!preferencesComplete) {
                    return const PreferencesScreen();
                  }
                  return const HomeScreen();
                },
              );
            },
          );
        },
      ),
      routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          PreferencesScreen.routeName: (context) => const PreferencesScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          ProfileScreen.routeName: (context) => const ProfileScreen(),
          UserSearchScreen.routeName: (context) => const UserSearchScreen(),
          FriendRequestsScreen.routeName: (context) => const FriendRequestsScreen(),
          AnimeSearchScreen.routeName: (context) => const AnimeSearchScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/user-profile') {
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId'] as int?;
            if (userId != null) {
              return MaterialPageRoute(builder: (_) => UserPublicProfileScreen(userId: userId));
            }
          }
          return null;
        },
    );
  }
}
