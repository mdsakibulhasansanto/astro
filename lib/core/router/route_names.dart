/// Route names and paths. Navigate with `context.goNamed(RouteNames.x)`.
class RouteNames {
  const RouteNames._();

  // Auth
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const signUp = 'sign-up';
  static const forgotPassword = 'forgot-password';
  static const resetPassword = 'reset-password';

  // Dashboard tab
  static const dashboard = 'dashboard';
  static const dailyReading = 'daily-reading';
  static const readingHistory = 'reading-history';
  static const aiChat = 'ai-chat';

  // Astrology tab
  static const astrology = 'astrology';
  static const birthInfo = 'birth-info';
  static const planetDetails = 'planet-details';

  // Room planner tab
  static const planner = 'planner';
  static const createHome = 'create-home';
  static const addRoom = 'add-room';
  static const roomSetup = 'room-setup';
  static const furniturePlanner = 'furniture-planner';
  static const recommendation = 'recommendation';
  static const recommendationHistory = 'recommendation-history';

  // Reading + profile tabs
  static const reading = 'reading';
  static const profile = 'profile';
  static const settings = 'settings';
  static const changePassword = 'change-password';
  static const legal = 'legal';
  static const premium = 'premium';
}

class RoutePaths {
  const RoutePaths._();

  static const splash = '/splash';
  static const onboarding = '/welcome';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  static const dashboard = '/home';
  static const astrology = '/astrology';
  static const planner = '/planner';
  static const reading = '/reading';
  static const profile = '/profile';

  /// Routes a signed-out user may open.
  static const public = {splash, onboarding, login, signUp, forgotPassword};
}
