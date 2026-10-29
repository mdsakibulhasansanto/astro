import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user, matching the `profiles` table.
class AppUserModel {
  const AppUserModel({required this.id, required this.email, this.name});

  final String id;
  final String email;
  final String? name;

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : email.split('@').first;

  factory AppUserModel.fromSupabaseUser(User user) => AppUserModel(
    id: user.id,
    email: user.email ?? '',
    name: user.userMetadata?['name'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUserModel && other.id == id && other.email == email && other.name == name;

  @override
  int get hashCode => Object.hash(id, email, name);
}
