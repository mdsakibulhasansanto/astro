import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../model/sign_up_model.dart';
import '../../riverpod/auth_provider.dart';
import '../../riverpod/auth_state_notifier.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToLogin() {
    ref.read(authStateNotifierProvider.notifier).clearMessage();
    context.goNamed(RouteNames.login);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final created = await ref
        .read(authStateNotifierProvider.notifier)
        .signUp(SignUpModel(name: _name.text, email: _email.text, password: _password.text));
    if (!mounted || !created) return;
    // With email confirmation on, the user is not signed in yet: Login
    // shows the "check your email" note.
    if (!ref.read(authStateNotifierProvider).isAuthenticated) {
      context.goNamed(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateNotifierProvider);

    return AuthScaffold(
      eyebrow: 'Get started',
      title: 'Create your account',
      subtitle: 'Save your chart, your rooms and your readings.',
      onBack: auth.isLoading ? null : _goToLogin,
      footer: AuthSwitchLink(
        question: 'Already have an account?',
        action: 'Log in',
        onTap: auth.isLoading ? null : _goToLogin,
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.status == AuthStatus.error && auth.message != null) ...[
                AuthBanner(message: auth.message!),
                const SizedBox(height: 18),
              ],
              AuthTextField(
                controller: _name,
                label: 'Name',
                hint: 'Your name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (v) => Validators.requiredText(v, 'Name'),
              ),
              const SizedBox(height: 16),
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
                hint: 'Create a password',
                helper: 'At least 6 characters.',
                icon: Icons.lock_outline,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirm,
                label: 'Confirm password',
                hint: 'Type it again',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 26),
              AuthPrimaryButton(
                label: 'Create account',
                loading: auth.isLoading,
                onPressed: _submit,
              ),
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
