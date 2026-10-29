import 'package:flutter/material.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/constants/astro_interpretations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/chart_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/section_card.dart';
import '../../model/aspect_model.dart';
import '../../model/astrology_result_model.dart';
import '../../riverpod/astrology_state_notifier.dart';
import 'chart_wheel.dart';
import 'element_balance_card.dart';
import 'insight_card.dart';
import 'kua_card.dart';

/// Chart tab: the wheel, key facts, balance, house cusps and Kua.
class ChartTab extends StatefulWidget {
  const ChartTab({super.key, required this.state});

  final AstrologyState state;

  @override
  State<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<ChartTab> {
  bool _aspects = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final result = widget.state.result!;
    final profile = widget.state.profile!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (!profile.hasBirthTime) ...[
          const NoteText(
            'Birth time unknown, so the rising sign, Midheaven and houses are not shown. '
            'Add a birth time to unlock them.',
          ),
          const SizedBox(height: 12),
        ],
        SectionCard(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: Column(
            children: [
              Center(
                child: ChartWheel(result: result, showAspects: _aspects),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final t in const [
                    AspectType.trine,
                    AspectType.sextile,
                    AspectType.square,
                    AspectType.opposition,
                  ])
                    _Legend(color: ChartPalette.aspect(t), label: t.label),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _aspects,
                        onChanged: (v) => setState(() => _aspects = v),
                        activeThumbColor: c.brass,
                      ),
                      Text('Aspects', style: TextStyle(color: c.muted, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _KeyFacts(result: result),
        const SizedBox(height: 16),
        ElementBalanceCard(result: result),
        if (result.hasHouses) ...[
          const SectionLabel('Houses · Placidus'),
          _HouseTable(result: result),
        ],
        if (widget.state.kua != null) ...[
          const SizedBox(height: 16),
          KuaCard(kua: widget.state.kua!),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: context.colors.muted, fontSize: 12.5)),
    ],
  );
}

/// Grid of headline facts: Sun, Moon, Rising, MC, chart ruler, Moon phase.
class _KeyFacts extends StatelessWidget {
  const _KeyFacts({required this.result});

  final AstrologyResultModel result;

  @override
  Widget build(BuildContext context) {
    String deg(double? l) => l == null ? '' : formatSignDegree(l);
    final sun = result.planet('Sun')!;
    final moon = result.planet('Moon')!;
    final ruler = result.ascendant == null ? null : signProfiles[result.ascendant]!.ruler;
    final facts = <(String, String, String)>[
      ('Sun', result.sunSign, deg(sun.longitude)),
      ('Moon', result.moonSign, deg(moon.longitude)),
      ('Rising', result.ascendant ?? 'Needs time', deg(result.ascendantLongitude)),
      (
        'Midheaven',
        result.mcLongitude == null ? '—' : signOfLongitude(result.mcLongitude!).name,
        deg(result.mcLongitude),
      ),
      ('Chart ruler', ruler ?? '—', ruler == null ? '' : 'in ${result.planet(ruler)?.sign ?? ''}'),
      (
        'Moon phase',
        result.moonPhase?.name ?? '—',
        result.moonPhase == null ? '' : '${(result.moonPhase!.illumination * 100).round()}% lit',
      ),
    ];
    return LayoutBuilder(
      builder: (context, cons) {
        final cols = cons.maxWidth > 520 ? 3 : 2;
        final w = (cons.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final f in facts) SizedBox(width: w, child: _Fact(f.$1, f.$2, f.$3))],
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, this.detail);

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overline(c.muted).copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.display(19, c.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (detail.isNotEmpty)
            Text(detail, style: AppTextStyles.mono(11.5, c.muted), maxLines: 1),
        ],
      ),
    );
  }
}

class _HouseTable extends StatelessWidget {
  const _HouseTable({required this.result});

  final AstrologyResultModel result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          for (final h in result.houses)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: h.number == 12 ? null : Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('${h.number}', style: AppTextStyles.mono(13, c.brass)),
                  ),
                  Expanded(
                    child: Text(
                      houseMeanings[h.number]!.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    signByName(h.sign).symbol + AppTextStyles.textVariation,
                    style: AppTextStyles.symbol(14, c.forAstroElement(signByName(h.sign).element)),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 112,
                    child: Text(
                      '${formatSignDegree(h.cusp)} ${h.sign}',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.mono(12.5, c.muted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
