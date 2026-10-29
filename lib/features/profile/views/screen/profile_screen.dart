import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../../auth/riverpod/auth_provider.dart';
import '../../../room_planner/riverpod/room_planner_provider.dart';

/// Profile tab: account, birth details summary and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateNotifierProvider.select((s) => s.user));
    final astrology = ref.watch(astrologyStateNotifierProvider);
    final homes = ref.watch(homesStateNotifierProvider);
    final c = context.colors;
    final profile = astrology.profile;
    final result = astrology.result;

    Future<void> signOut() async {
      final ok = await showConfirm(
        context,
        title: 'Log out?',
        message: 'Your chart and rooms stay saved to your account.',
        confirm: 'Log out',
      );
      if (ok) await ref.read(authStateNotifierProvider.notifier).logout();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(RouteNames.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SectionCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: c.brass,
                  child: Text(
                    (user?.displayName ?? '?').characters.first.toUpperCase(),
                    style: TextStyle(color: c.surface, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? '', style: Theme.of(context).textTheme.titleLarge),
                      Text(user?.email ?? '', style: TextStyle(color: c.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Birth details',
            child: profile == null
                ? Text('Not entered yet.', style: TextStyle(color: c.muted))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row('Date', formatReadableDate(profile.birthDate)),
                      _Row('Time', profile.birthTime ?? 'Unknown'),
                      _Row('Place', profile.birthPlace),
                      if (result != null)
                        _Row(
                          'Signs',
                          '${result.sunSign} Sun · ${result.moonSign} Moon'
                              '${result.ascendant != null ? ' · ${result.ascendant} Rising' : ''}',
                        ),
                      if (astrology.kua != null) _Row('Kua number', '${astrology.kua}'),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.goNamed(RouteNames.birthInfo),
            icon: const Icon(Icons.edit_outlined),
            label: Text(profile == null ? 'Enter birth details' : 'Edit birth details'),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'My homes',
            child: Text(
              '${homes.homes.length} ${homes.homes.length == 1 ? 'home' : 'homes'} · '
              '${homes.allRooms.length} ${homes.allRooms.length == 1 ? 'room' : 'rooms'}',
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: c.fire),
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: TextStyle(color: context.colors.muted)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
