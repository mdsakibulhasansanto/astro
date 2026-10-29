import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/night_sky.dart';

/// Shown while the saved session is restored. The router moves on as soon
/// as the auth state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SkyColors.top,
        body: NightSky(
          orbitCenter: Alignment.center,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 92, onDark: true),
                const SizedBox(height: 22),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Astro ', style: AppTextStyles.display(40, SkyColors.text)),
                      TextSpan(
                        text: 'Home',
                        style: AppTextStyles.display(40, SkyColors.brass, italic: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your birth chart, mapped onto your home.',
                  style: TextStyle(color: SkyColors.muted, fontSize: 14.5),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: SkyColors.brass),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
