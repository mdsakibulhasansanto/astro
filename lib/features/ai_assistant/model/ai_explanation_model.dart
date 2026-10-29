/// Plain-language explanation returned by the `ai-explain` function.
class AiExplanationModel {
  const AiExplanationModel({required this.text});

  final String text;

  factory AiExplanationModel.fromJson(Map<String, dynamic> j) =>
      AiExplanationModel(text: (j['explanation'] as String? ?? '').trim());
}
