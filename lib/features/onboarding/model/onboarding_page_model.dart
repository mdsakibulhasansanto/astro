enum OnboardingArt { chart, plan, reading }

/// One slide of the intro.
class OnboardingPageModel {
  const OnboardingPageModel({
    required this.art,
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final OnboardingArt art;
  final String eyebrow;
  final String title;
  final String body;
}

const onboardingPages = <OnboardingPageModel>[
  OnboardingPageModel(
    art: OnboardingArt.chart,
    eyebrow: 'Your sky',
    title: 'A birth chart worked out precisely',
    body:
        'Enter when and where you were born. An astronomy engine places the Sun, '
        'Moon and planets exactly, and finds your rising sign and element balance.',
  ),
  OnboardingPageModel(
    art: OnboardingArt.plan,
    eyebrow: 'Your space',
    title: 'Draw your rooms, place your furniture',
    body:
        'Add each room with its size, door, window and compass direction. Then '
        'drag, turn and resize furniture on a plan laid over the nine bagua zones.',
  ),
  OnboardingPageModel(
    art: OnboardingArt.reading,
    eyebrow: 'Your reading',
    title: 'Advice made for you and your room',
    body:
        'Traditional feng shui rules, matched to your chart and Kua directions, suggest '
        'where things go, which colours help and what to add. In plain words.',
  ),
];
