import '../../../core/utils/formatters.dart';

enum KuaBasis {
  female,
  male;

  static KuaBasis fromName(String? v) => v == 'male' ? male : female;

  String get label => this == male ? 'Male' : 'Female';
}

/// Row in `birth_profiles`: what the user entered on Birth Information.
class BirthProfileModel {
  const BirthProfileModel({
    this.id,
    required this.userId,
    required this.name,
    required this.birthDate,
    this.birthTime,
    required this.birthPlace,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.kuaBasis,
  });

  final String? id;
  final String userId;
  final String name;
  final DateTime birthDate;

  /// Local clock time `HH:mm`, or null when the user doesn't know it.
  /// Without it there is no rising sign or houses.
  final String? birthTime;
  final String birthPlace;
  final double latitude;
  final double longitude;

  /// IANA timezone id of the birthplace, e.g. `Asia/Dhaka`.
  final String timezone;

  /// Feng shui Kua numbers depend on birth sex.
  final KuaBasis kuaBasis;

  bool get hasBirthTime => birthTime != null && birthTime!.isNotEmpty;

  factory BirthProfileModel.fromJson(Map<String, dynamic> j) => BirthProfileModel(
    id: j['id'] as String?,
    userId: j['user_id'] as String,
    name: (j['name'] as String?) ?? '',
    birthDate: DateTime.parse(j['birth_date'] as String),
    // Postgres `time` comes back as HH:mm:ss.
    birthTime: (j['birth_time'] as String?)?.substring(0, 5),
    birthPlace: j['birth_place'] as String,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    timezone: j['timezone'] as String,
    kuaBasis: KuaBasis.fromName(j['kua_basis'] as String?),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name.trim(),
    'birth_date': formatIsoDate(birthDate),
    'birth_time': hasBirthTime ? birthTime : null,
    'birth_place': birthPlace,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'kua_basis': kuaBasis.name,
  };
}
