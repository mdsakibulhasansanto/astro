/// Supabase Edge Function names (relative to [Env.functionsUrl]) and
/// database table names.
class ApiEndpoints {
  const ApiEndpoints._();

  // Edge Functions
  static const astrologyChart = 'astrology-chart';
  static const aiExplain = 'ai-explain';
  static const deleteAccount = 'delete-account';
  static const dailyReading = 'daily-reading';
  static const aiChat = 'ai-chat';
  static const verifyPurchase = 'verify-purchase';

  // Tables
  static const profiles = 'profiles';
  static const birthProfiles = 'birth_profiles';
  static const astrologyResults = 'astrology_results';
  static const homes = 'homes';
  static const rooms = 'rooms';
  static const furniture = 'furniture';
  static const roomDesigns = 'room_designs';
  static const recommendationHistory = 'recommendation_history';
  static const dailyReadings = 'daily_readings';
}
