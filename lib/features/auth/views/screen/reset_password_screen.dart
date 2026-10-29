import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../riverpod/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

/// Opened from the password-reset email link: choose a new password.
/// Also used from Settings to change the password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref.read(authStateNotifierProvider.notifier).updatePassword(_password.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
      // After a reset link the router moves on by itself; from Settings, go back.
      if (widget.fromSettings && Navigator.of(context).canPop()) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      eyebrow: widget.fromSettings ? 'Security' : 'Almost there',
      title: widget.fromSettings ? 'Change password' : 'New password',
      subtitle: 'Choose a password you have not used here before.',
      onBack: widget.fromSettings ? () => Navigator.of(context).maybePop() : null,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[AuthBanner(message: _error!), const SizedBox(height: 18)],
              AuthTextField(
                controller: _password,
                label: 'New password',
                hint: 'At least 6 characters',
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
              AuthPrimaryButton(label: 'Save password', loading: _saving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
