import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/env.dart';
import 'core/utils/preferences.dart';
import 'features/room_planner/views/widgets/furniture_images.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const ConfigMissingApp());
    return;
  }

  // Restores the saved session before the first frame.
  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);

  // Read once here so the router knows synchronously whether to show the intro.
  final prefs = await SharedPreferences.getInstance();
  await FurnitureImages.load();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AstroHomeApp(),
    ),
  );
}
