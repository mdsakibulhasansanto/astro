import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_assistant/views/screen/ai_chat_screen.dart';
import '../../features/astrology/views/screen/astrology_result_screen.dart';
import '../../features/astrology/views/screen/birth_info_screen.dart';
import '../../features/astrology/views/screen/planet_details_screen.dart';
import '../../features/auth/riverpod/auth_provider.dart';
import '../../features/auth/riverpod/auth_state_notifier.dart';
import '../../features/auth/views/screen/forgot_password_screen.dart';
import '../../features/auth/views/screen/login_screen.dart';
import '../../features/auth/views/screen/reset_password_screen.dart';
import '../../features/auth/views/screen/sign_up_screen.dart';
import '../../features/auth/views/screen/splash_screen.dart';
import '../../features/bottom_nav_bar/views/screen/bottom_nav_shell.dart';
import '../../features/daily_reading/views/screen/daily_reading_screen.dart';
import '../../features/daily_reading/views/screen/reading_history_screen.dart';
import '../../features/dashboard/views/screen/dashboard_screen.dart';
import '../../features/onboarding/riverpod/onboarding_provider.dart';
import '../../features/onboarding/views/screen/onboarding_screen.dart';
import '../../features/profile/views/screen/profile_screen.dart';
import '../../features/recommendation/views/screen/reading_screen.dart';
import '../../features/recommendation/views/screen/recommendation_history_screen.dart';
import '../../features/recommendation/views/screen/recommendation_result_screen.dart';
import '../../features/room_planner/views/screen/create_home_screen.dart';
import '../../features/room_planner/views/screen/furniture_planner_screen.dart';
import '../../features/room_planner/views/screen/room_planner_home_screen.dart';
import '../../features/room_planner/views/screen/room_setup_screen.dart';
import '../../features/settings/model/legal_documents.dart';
import '../../features/settings/views/screen/legal_screen.dart';
import '../../features/settings/views/screen/settings_screen.dart';
import 'route_names.dart';
import '../../features/subscription/views/screen/premium_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Where the auth status and onboarding flag should send a location, or
/// null to stay. Kept separate from the router so it can be unit tested.
String? authRedirect(
  AuthStatus status,
  String location, {
  required bool onboardingDone,
  bool passwordRecovery = false,
}) {
  if (status == AuthStatus.initial) {
    return location == RoutePaths.splash ? null : RoutePaths.splash;
  }
  final isPublic = RoutePaths.public.contains(location);
  if (status == AuthStatus.authenticated) {
    // Opened a reset link: choose a new password before anything else.
    if (passwordRecovery) {
      return location == RoutePaths.resetPassword ? null : RoutePaths.resetPassword;
    }
    if (location == RoutePaths.resetPassword) return RoutePaths.dashboard;
    return isPublic ? RoutePaths.dashboard : null;
  }
  // Signed out, or a login/sign-up in progress or failed.
  if (!onboardingDone) {
    return location == RoutePaths.onboarding ? null : RoutePaths.onboarding;
  }
  if (location == RoutePaths.login ||
      location == RoutePaths.signUp ||
      location == RoutePaths.forgotPassword) {
    return null;
  }
  return RoutePaths.login;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Bridges auth state to GoRouter so redirects re-run on login/logout.
  final authStatus = ValueNotifier<AuthStatus>(ref.read(authStateNotifierProvider).status);
  ref.listen(
    authStateNotifierProvider.select((s) => s.status),
    (_, next) => authStatus.value = next,
  );
  final recovery = ValueNotifier<bool>(false);
  ref.listen(
    authStateNotifierProvider.select((s) => s.passwordRecovery),
    (_, next) => recovery.value = next,
  );
  final onboardingDone = ValueNotifier<bool>(ref.read(onboardingStateNotifierProvider));
  ref.listen(onboardingStateNotifierProvider, (_, next) => onboardingDone.value = next);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: Listenable.merge([authStatus, onboardingDone, recovery]),
    redirect: (context, state) => authRedirect(
      ref.read(authStateNotifierProvider).status,
      state.matchedLocation,
      onboardingDone: ref.read(onboardingStateNotifierProvider),
      passwordRecovery: ref.read(authStateNotifierProvider).passwordRecovery,
    ),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        name: RouteNames.signUp,
        builder: (_, _) => const SignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/premium',
        name: RouteNames.premium,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/ask',
        name: RouteNames.aiChat,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const AiChatScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'password',
            name: RouteNames.changePassword,
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const ResetPasswordScreen(fromSettings: true),
          ),
          GoRoute(
            path: 'legal/:doc',
            name: RouteNames.legal,
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) => LegalScreen(
              document: LegalDocument.values.firstWhere(
                (d) => d.name == state.pathParameters['doc'],
                orElse: () => LegalDocument.privacy,
              ),
            ),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => BottomNavShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                name: RouteNames.dashboard,
                builder: (_, _) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'today',
                    name: RouteNames.dailyReading,
                    builder: (_, _) => const DailyReadingScreen(),
                    routes: [
                      GoRoute(
                        path: 'history',
                        name: RouteNames.readingHistory,
                        builder: (_, _) => const ReadingHistoryScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.astrology,
                name: RouteNames.astrology,
                builder: (_, _) => const AstrologyResultScreen(),
                routes: [
                  GoRoute(
                    path: 'birth-info',
                    name: RouteNames.birthInfo,
                    builder: (_, _) => const BirthInfoScreen(),
                  ),
                  GoRoute(
                    path: 'planet/:name',
                    name: RouteNames.planetDetails,
                    builder: (_, state) =>
                        PlanetDetailsScreen(planetName: state.pathParameters['name']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.planner,
                name: RouteNames.planner,
                builder: (_, _) => const RoomPlannerHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'new-home',
                    name: RouteNames.createHome,
                    builder: (_, _) => const CreateHomeScreen(),
                  ),
                  GoRoute(
                    path: 'home/:homeId/new-room',
                    name: RouteNames.addRoom,
                    builder: (_, state) => RoomSetupScreen(homeId: state.pathParameters['homeId']),
                  ),
                  // The planner gets the full screen, above the tab bar.
                  GoRoute(
                    path: 'room/:roomId',
                    name: RouteNames.furniturePlanner,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, state) =>
                        FurniturePlannerScreen(roomId: state.pathParameters['roomId']!),
                    routes: [
                      GoRoute(
                        path: 'setup',
                        name: RouteNames.roomSetup,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) =>
                            RoomSetupScreen(roomId: state.pathParameters['roomId']),
                      ),
                      GoRoute(
                        path: 'recommendation',
                        name: RouteNames.recommendation,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) =>
                            RecommendationResultScreen(roomId: state.pathParameters['roomId']!),
                      ),
                      GoRoute(
                        path: 'history',
                        name: RouteNames.recommendationHistory,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, state) =>
                            RecommendationHistoryScreen(roomId: state.pathParameters['roomId']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.reading,
                name: RouteNames.reading,
                builder: (_, _) => const ReadingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authStatus.dispose();
    recovery.dispose();
    onboardingDone.dispose();
  });
  return router;
});
