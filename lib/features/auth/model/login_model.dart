/// Credentials entered on the Login screen.
class LoginModel {
  const LoginModel({required this.email, required this.password});

  final String email;
  final String password;

  LoginModel normalized() => LoginModel(email: email.trim().toLowerCase(), password: password);
}
