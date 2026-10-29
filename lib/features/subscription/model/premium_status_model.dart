/// Google Play subscription product ids. Create subscriptions with these
/// ids in Play Console → Monetize → Subscriptions.
class PremiumProducts {
  const PremiumProducts._();

  static const monthly = 'astro_home_premium_monthly';
  static const yearly = 'astro_home_premium_yearly';
  static const all = {monthly, yearly};
}

/// What Premium unlocks; shown on the Premium screen.
const premiumBenefits = <(String, String)>[
  (
    'AI interior assistant',
    'Chat about your rooms and get written readings of your chart and layout.',
  ),
  ('Advanced room recommendations', 'One tap to apply the suggested layout to any room.'),
  ('Unlimited saved designs', 'Free accounts keep up to 3 designs per room.'),
  (
    'Premium astrology reports',
    'Full planet, aspect and pattern insights, exportable with your plans.',
  ),
];

/// Free accounts can keep this many saved designs per room.
const freeDesignLimit = 3;

/// Premium fields on the user's `profiles` row.
class PremiumStatusModel {
  const PremiumStatusModel({this.isPremium = false, this.until, this.product});

  final bool isPremium;

  /// Renewal or expiry time; null for Premium granted without an end date.
  final DateTime? until;
  final String? product;

  bool get isActive => isPremium && (until == null || until!.isAfter(DateTime.now()));

  factory PremiumStatusModel.fromJson(Map<String, dynamic> j) => PremiumStatusModel(
    isPremium: (j['is_premium'] as bool?) ?? false,
    until: DateTime.tryParse((j['premium_until'] as String?) ?? ''),
    product: j['premium_product'] as String?,
  );
}
