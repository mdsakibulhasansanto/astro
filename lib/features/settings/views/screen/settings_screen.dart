import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../auth/riverpod/auth_provider.dart';
import '../../../profile/riverpod/profile_provider.dart';
import '../../model/legal_documents.dart';
import '../../riverpod/settings_provider.dart';
import '../../../subscription/riverpod/subscription_provider.dart';

/// Account, appearance, legal and account-deletion settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final name = await showTextPrompt(context, title: 'Your name', label: 'Name', initial: current);
    if (name == null || name.isEmpty || name == current || !context.mounted) return;
    final error = await ref.read(profileStateNotifierProvider.notifier).updateName(name);
    if (context.mounted) _toast(context, error ?? 'Name updated.');
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final first = await showConfirm(
      context,
      title: 'Delete your account?',
      message:
          'This permanently deletes your profile, birth chart, homes, rooms and layouts. '
          'It cannot be undone.',
      confirm: 'Continue',
    );
    if (!first || !context.mounted) return;
    final typed = await showTextPrompt(
      context,
      title: 'Type DELETE to confirm',
      label: 'Confirmation',
      confirm: 'Delete account',
    );
    if (typed != 'DELETE' || !context.mounted) {
      if (typed != null && context.mounted) _toast(context, 'Account not deleted.');
      return;
    }
    final error = await ref.read(profileStateNotifierProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    if (error != null) {
      _toast(context, error);
      return;
    }
    await ref.read(authStateNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final user = ref.watch(authStateNotifierProvider.select((s) => s.user));
    final settings = ref.watch(settingsStateNotifierProvider);
    final busy = ref.watch(profileStateNotifierProvider.select((s) => s.busy));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          const _Header('Account'),
          _Group(
            children: [
              _Tile(
                icon: Icons.workspace_premium_outlined,
                title: 'Astro Home Premium',
                value: ref.watch(isPremiumProvider) ? 'Active' : 'Upgrade',
                onTap: () => context.pushNamed(RouteNames.premium),
              ),
              _Tile(
                icon: Icons.person_outline,
                title: 'Name',
                value: user?.displayName,
                onTap: busy ? null : () => _editName(context, ref, user?.name ?? ''),
              ),
              _Tile(icon: Icons.mail_outline, title: 'Email', value: user?.email),
              _Tile(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: () => context.pushNamed(RouteNames.changePassword),
              ),
              _Tile(
                icon: Icons.cake_outlined,
                title: 'Birth details',
                onTap: () => context.goNamed(RouteNames.birthInfo),
              ),
            ],
          ),
          const _Header('Appearance'),
          _Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (s) =>
                            ref.read(settingsStateNotifierProvider.notifier).setThemeMode(s.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const _Header('Notifications'),
          _Group(
            children: [
              SwitchListTile(
                secondary: Icon(Icons.notifications_outlined, color: c.muted),
                title: const Text(
                  'Daily reading reminder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  settings.dailyReminder
                      ? 'Every day at ${settings.reminderTime.format(context)}'
                      : 'Off',
                  style: TextStyle(color: c.muted),
                ),
                value: settings.dailyReminder,
                activeThumbColor: c.brass,
                onChanged: (on) async {
                  final msg = await ref
                      .read(settingsStateNotifierProvider.notifier)
                      .setReminder(enabled: on);
                  if (msg != null && context.mounted) _toast(context, msg);
                },
              ),
              if (settings.dailyReminder)
                _Tile(
                  icon: Icons.schedule_outlined,
                  title: 'Reminder time',
                  value: settings.reminderTime.format(context),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: settings.reminderTime,
                    );
                    if (t == null) return;
                    final msg = await ref
                        .read(settingsStateNotifierProvider.notifier)
                        .setReminder(enabled: true, time: t);
                    if (msg != null && context.mounted) _toast(context, msg);
                  },
                ),
            ],
          ),
          const _Header('About'),
          _Group(
            children: [
              _Tile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => context.pushNamed(
                  RouteNames.legal,
                  pathParameters: {'doc': LegalDocument.privacy.name},
                ),
              ),
              _Tile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => context.pushNamed(
                  RouteNames.legal,
                  pathParameters: {'doc': LegalDocument.terms.name},
                ),
              ),
              const _Tile(icon: Icons.info_outline, title: 'Version', value: '1.0.0'),
            ],
          ),
          const _Header('Account actions'),
          _Group(
            children: [
              _Tile(
                icon: Icons.logout,
                title: 'Log out',
                onTap: () async {
                  final ok = await showConfirm(
                    context,
                    title: 'Log out?',
                    message: 'Your chart and rooms stay saved to your account.',
                    confirm: 'Log out',
                  );
                  if (ok) await ref.read(authStateNotifierProvider.notifier).logout();
                },
              ),
              _Tile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete account',
                color: c.fire,
                onTap: busy ? null : () => _deleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
    child: Text(text.toUpperCase(), style: AppTextStyles.overline(context.colors.muted)),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.value, this.onTap, this.color});

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? c.muted),
      title: Text(
        title,
        style: TextStyle(color: color ?? c.ink, fontWeight: FontWeight.w600),
      ),
      subtitle: value == null ? null : Text(value!, style: TextStyle(color: c.muted)),
      trailing: onTap == null ? null : Icon(Icons.chevron_right, color: c.muted),
    );
  }
}
