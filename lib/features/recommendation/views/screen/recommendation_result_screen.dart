import 'package:flutter/material.dart';

import '../widgets/recommendation_view.dart';

/// Recommendation Result for a room, opened from the Furniture Planner.
class RecommendationResultScreen extends StatelessWidget {
  const RecommendationResultScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: RecommendationView(roomId: roomId),
    );
  }
}
