import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../riverpod/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

/// Asks for an email and sends a reset link that opens the app.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await ref.read(authStateNotifierProvider.notifier).sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: 'Account help',
      title: 'Reset password',
      subtitle: 'We will email you a link to choose a new one.',
      onBack: () => context.goNamed(RouteNames.login),
      footer: AuthSwitchLink(
        question: 'Remembered it?',
        action: 'Log in',
        onTap: () => context.goNamed(RouteNames.login),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sent) ...[
              const AuthBanner(
                isError: false,
                message:
                    'Check your email. Open the reset link on this phone and Astro Home will '
                    'ask for your new password.',
              ),
              const SizedBox(height: 18),
            ],
            if (_error != null) ...[AuthBanner(message: _error!), const SizedBox(height: 18)],
            AuthTextField(
              controller: _email,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 26),
            AuthPrimaryButton(
              label: _sent ? 'Send again' : 'Send reset link',
              loading: _sending,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
