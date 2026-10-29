/// Form field validators shared across features.
class Validators {
  const Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredText(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return v.length < 6 ? 'Use at least 6 characters' : null;
  }

  static String? Function(String?) numberInRange(
    double min,
    double max, [
    String field = 'Value',
  ]) => (v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null) return '$field must be a number';
    if (n < min || n > max) return '$field must be $min–$max';
    return null;
  };
}
