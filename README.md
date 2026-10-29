# Astro Home — Flutter app

Birth chart + feng shui room planner. Flutter, Riverpod (`StateNotifier` /
`StateNotifierProvider` from `flutter_riverpod/legacy.dart`), GoRouter, Dio,
Supabase.

## Structure

```
lib/
├── core/            constants, network (Dio + Supabase), router, theme, utils, widgets
├── features/
│   ├── auth/            model · repository · riverpod · views (splash, login, sign up)
│   ├── bottom_nav_bar/  views (4-tab shell)
│   ├── astrology/       birth info, chart result, planet details
│   ├── room_planner/    homes, room setup, interactive furniture planner
│   ├── recommendation/  rule engine (repository/), Reading tab, result screen
│   ├── ai_assistant/    AI explanation (calls the ai-explain function)
│   └── profile/         profile tab
├── app.dart
└── main.dart
supabase/
├── migrations/      tables, row-level security, admin_stats()
└── functions/       astrology-chart (astronomy-engine), ai-explain (Claude)
```

Who calculates what:

- **Planets, signs, houses, element balance:** the `astrology-chart` Edge Function (astronomy-engine). It is the only writer of `astrology_results`.
- **Kua number and room recommendations:** pure Dart rules, in `core/utils/kua_calculator.dart` and `features/recommendation/repository/recommendation_engine.dart`.
- **AI:** the `ai-explain` function only explains results that are already calculated.

## Setup

1. Create a Supabase project, then run `supabase/migrations/20261029000000_init.sql` in its SQL editor (or `supabase db push`).
2. Deploy the functions and set the AI key:

   ```bash
   npx supabase login
   npx supabase link --project-ref YOUR-PROJECT-REF
   npx supabase functions deploy astrology-chart
   npx supabase functions deploy ai-explain
   npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
   ```

3. The app already points at the astro-home project (defaults in
   `lib/core/constants/env.dart`), so this is enough:

   ```bash
   flutter run
   ```

   To use a different Supabase project, copy `env.example.json` to `env.json`, fill it in,
   and run `flutter run --dart-define-from-file=env.json`.

4. To make an admin for the dashboard, run this once in the SQL editor:
   `update public.profiles set role = 'admin' where email = 'you@example.com';`

## Checks

```bash
flutter analyze
flutter test
```

## Live backend (astro-home Supabase project)

Already done: all migrations in `supabase/migrations`, and these Edge Functions:
`astrology-chart`, `daily-reading`, `ai-explain`, `ai-chat`, `delete-account`,
`verify-purchase`. Redirect URL `astrohome://auth-callback` is allowed in Auth → URL Configuration.

## Setup only you can do

| Feature | What to do |
|---|---|
| AI reading + AI chat | Supabase → Edge Functions → Secrets: `ANTHROPIC_API_KEY` |
| Google Sign-In | Google Cloud: create an OAuth client (Web); Supabase → Authentication → Sign In / Providers → Google: paste client ID + secret |
| Premium (Google Play) | Play Console: subscriptions `astro_home_premium_monthly` and `astro_home_premium_yearly`; a service account with Play access; Supabase secrets `GOOGLE_PLAY_PACKAGE_NAME` (`com.astrohome.astro_home`) and `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` |
| Test Premium without billing | Admin dashboard → Users → user → **Grant Premium** |
| Admin account | SQL editor: `update public.profiles set role = 'admin' where email = 'you@example.com';` |
