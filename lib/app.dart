import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/brand_logo.dart';
import 'features/settings/riverpod/settings_provider.dart';
import 'features/subscription/riverpod/subscription_provider.dart';

/// Root widget: theme (light/dark follows the system) and GoRouter.
class AstroHomeApp extends ConsumerWidget {
  const AstroHomeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the store purchase listener alive so pending purchases finish.
    ref.listen(subscriptionStateNotifierProvider, (_, _) {});
    return MaterialApp.router(
      title: 'Astro Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(settingsStateNotifierProvider.select((s) => s.themeMode)),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

/// Shown instead of the app when the Supabase keys were not provided.
class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLogo(size: 34),
                  const SizedBox(height: 28),
                  Text(
                    'Supabase is not configured',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Copy env.example.json to env.json, fill in SUPABASE_URL and '
                    'SUPABASE_PUBLISHABLE_KEY, then run:\n\n'
                    'flutter run --dart-define-from-file=env.json',
                    style: TextStyle(color: context.colors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
