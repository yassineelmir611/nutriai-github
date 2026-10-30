import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/navigation/main_nav_shell.dart';
import '../../presentation/screens/analyze_food_screen.dart';
import '../../presentation/screens/analysis_result_screen.dart';
import '../../presentation/screens/chat_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/gallery_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/meal_detail_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainNavShell(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/analyze', builder: (_, __) => const AnalyzeFoodScreen()),
          GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(
        path: '/meal/:id',
        builder: (context, state) =>
            MealDetailScreen(mealId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/analysis-result',
        builder: (context, state) =>
            AnalysisResultScreen(args: state.extra as AnalysisResultArgs),
      ),
    ],
  );
});
