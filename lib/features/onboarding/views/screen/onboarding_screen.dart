import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/night_sky.dart';
import '../../model/onboarding_page_model.dart';
import '../../riverpod/onboarding_provider.dart';
import '../widgets/onboarding_art.dart';
import '../widgets/page_dots.dart';

/// Three-slide intro shown once per device, before the auth screens.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  bool get _isLast => _index == onboardingPages.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish(String routeName) async {
    await ref.read(onboardingStateNotifierProvider.notifier).complete();
    if (mounted) context.goNamed(routeName);
  }

  void _next() {
    if (_isLast) {
      _finish(RouteNames.signUp);
    } else {
      _pages.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SkyColors.top,
        body: NightSky(
          orbitCenter: const Alignment(0, -0.28),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      const BrandLogo(size: 22, onDark: true),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _isLast ? null : () => _finish(RouteNames.login),
                          style: TextButton.styleFrom(foregroundColor: SkyColors.muted),
                          child: const Text('Skip'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: onboardingPages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _Slide(page: onboardingPages[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          PageDots(count: onboardingPages.length, index: _index),
                          const Spacer(),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                backgroundColor: SkyColors.brass,
                                foregroundColor: SkyColors.top,
                                padding: const EdgeInsets.symmetric(horizontal: 26),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_isLast ? 'Get started' : 'Next'),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => _finish(RouteNames.login),
                        style: TextButton.styleFrom(foregroundColor: SkyColors.text),
                        child: const Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: SkyColors.muted),
                            children: [
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: SkyColors.brass,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.page});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final compact = cons.maxHeight < 560;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 20),
                      child: OnboardingArtView(art: page.art),
                    ),
                  ),
                ),
              ),
              Text(
                page.eyebrow.toUpperCase(),
                style: AppTextStyles.overline(SkyColors.brass).copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              Text(page.title, style: AppTextStyles.display(compact ? 26 : 32, SkyColors.text)),
              const SizedBox(height: 12),
              Text(
                page.body,
                style: const TextStyle(color: SkyColors.muted, fontSize: 15, height: 1.5),
              ),
              SizedBox(height: compact ? 8 : 20),
            ],
          ),
        );
      },
    );
  }
}
