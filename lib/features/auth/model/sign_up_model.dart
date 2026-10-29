/// Details entered on the Register screen.
class SignUpModel {
  const SignUpModel({required this.name, required this.email, required this.password});

  final String name;
  final String email;
  final String password;

  String get normalizedEmail => email.trim().toLowerCase();

  /// Stored in Supabase `raw_user_meta_data`; the `handle_new_user`
  /// trigger copies `name` into the `profiles` table.
  Map<String, dynamic> toMetadata() => {'name': name.trim()};
}
