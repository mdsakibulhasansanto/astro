import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/night_sky.dart';
import '../../model/premium_status_model.dart';
import '../../riverpod/subscription_provider.dart';

/// Free vs Premium, the Google Play plans, buy and restore.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionStateNotifierProvider);
    final notifier = ref.read(subscriptionStateNotifierProvider.notifier);

    ref.listen(subscriptionStateNotifierProvider.select((s) => s.message), (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SkyColors.top,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: SkyColors.text,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        extendBodyBehindAppBar: true,
        body: NightSky(
          orbitCenter: const Alignment(0, -0.6),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
              children: [
                const Center(child: BrandMark(size: 72, onDark: true)),
                const SizedBox(height: 16),
                Text(
                  'Astro Home Premium',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(32, SkyColors.text),
                ),
                const SizedBox(height: 6),
                Text(
                  state.isPremium
                      ? 'You have Premium${state.status.until != null ? ' until ${formatReadableDate(state.status.until!.toLocal())}' : ''}. Thank you!'
                      : 'Everything in Astro Home, with your personal AI assistant.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SkyColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 24),
                for (final (title, body) in premiumBenefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: SkyColors.brass, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: SkyColors.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                body,
                                style: const TextStyle(color: SkyColors.muted, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (state.loading)
                  const Center(child: CircularProgressIndicator(color: SkyColors.brass))
                else if (!state.isPremium) ...[
                  if (!state.storeAvailable)
                    const _Note(
                      'Google Play Billing is not available on this device or build. '
                      'Install the app from Google Play to subscribe.',
                    )
                  else if (state.products.isEmpty)
                    const _Note(
                      'Subscription plans are not available yet. They appear once they are '
                      'published in Google Play Console.',
                    )
                  else
                    for (final p in state.products)
                      _PlanButton(product: p, busy: state.busy, onTap: () => notifier.buy(p)),
                ],
                const SizedBox(height: 10),
                TextButton(
                  onPressed: state.busy || !state.storeAvailable ? null : notifier.restore,
                  style: TextButton.styleFrom(foregroundColor: SkyColors.muted),
                  child: const Text('Restore purchases'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Subscriptions renew automatically until cancelled in Google Play. '
                  'You can cancel at any time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SkyColors.muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanButton extends StatelessWidget {
  const _PlanButton({required this.product, required this.busy, required this.onTap});

  final ProductDetails product;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yearly = product.id == PremiumProducts.yearly;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 60,
        child: FilledButton(
          onPressed: busy ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: yearly ? SkyColors.brass : Colors.white.withValues(alpha: 0.1),
            foregroundColor: yearly ? SkyColors.top : SkyColors.text,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  yearly ? 'Yearly · best value' : 'Monthly',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              Text(
                product.price,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: SkyColors.ring),
    ),
    child: Text(text, style: const TextStyle(color: SkyColors.muted, fontSize: 13.5)),
  );
}
