import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../model/login_model.dart';
import '../../riverpod/auth_provider.dart';
import '../../riverpod/auth_state_notifier.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authStateNotifierProvider.notifier)
        .login(LoginModel(email: _email.text, password: _password.text));
  }

  @override
  Widget build(BuildContext context) {
    // Navigation after a successful login is handled by the router redirect.
    final auth = ref.watch(authStateNotifierProvider);

    return AuthScaffold(
      eyebrow: 'Welcome back',
      title: 'Log in',
      subtitle: 'Your chart and room plans are waiting.',
      footer: AuthSwitchLink(
        question: 'New to Astro Home?',
        action: 'Create an account',
        onTap: auth.isLoading
            ? null
            : () {
                ref.read(authStateNotifierProvider.notifier).clearMessage();
                context.goNamed(RouteNames.signUp);
              },
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.message != null) ...[
                AuthBanner(message: auth.message!, isError: auth.status == AuthStatus.error),
                const SizedBox(height: 18),
              ],
              AuthTextField(
                controller: _email,
                label: 'Email',
                hint: 'you@example.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _password,
                label: 'Password',
                hint: 'Your password',
                icon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.password,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () {
                          ref.read(authStateNotifierProvider.notifier).clearMessage();
                          context.goNamed(RouteNames.forgotPassword);
                        },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 10),
              AuthPrimaryButton(label: 'Log in', loading: auth.isLoading, onPressed: _submit),
              GoogleSignInSection(
                onPressed: auth.isLoading
                    ? null
                    : ref.read(authStateNotifierProvider.notifier).signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
