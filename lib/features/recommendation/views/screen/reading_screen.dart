import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../astrology/riverpod/astrology_provider.dart';
import '../../../astrology/riverpod/astrology_state_notifier.dart';
import '../../../room_planner/riverpod/homes_state_notifier.dart';
import '../../../room_planner/riverpod/room_planner_provider.dart';
import '../widgets/recommendation_view.dart';

/// Reading tab: the personalized reading for a chosen room.
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  String? _roomId;

  @override
  Widget build(BuildContext context) {
    final homes = ref.watch(homesStateNotifierProvider);
    final astrologyStatus = ref.watch(astrologyStateNotifierProvider.select((s) => s.status));
    final rooms = homes.allRooms;

    Widget body;
    if (homes.status == HomesStatus.loading || homes.status == HomesStatus.initial) {
      body = const LoadingView();
    } else if (homes.status == HomesStatus.error) {
      body = ErrorView(
        message: homes.message ?? 'Could not load your rooms.',
        onRetry: ref.read(homesStateNotifierProvider.notifier).load,
      );
    } else if (rooms.isEmpty) {
      body = EmptyView(
        icon: Icons.menu_book_outlined,
        title: 'No rooms to read yet',
        message: 'Add a room and its furniture in the Room Planner to get your reading.',
        actionLabel: 'Open Room Planner',
        onAction: () => context.goNamed(RouteNames.planner),
      );
    } else {
      final selected = rooms.any((r) => r.id == _roomId) ? _roomId! : rooms.first.id!;
      body = RecommendationView(
        key: ValueKey(selected),
        roomId: selected,
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (astrologyStatus == AstrologyStatus.empty) ...[
                const NoteText(
                  'Add your birth details on the Astrology tab to personalise this reading.',
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Room'),
                isExpanded: true,
                items: [
                  for (final h in homes.homes)
                    for (final r in h.rooms)
                      DropdownMenuItem(
                        value: r.id,
                        child: Text(
                          homes.homes.length > 1 ? '${h.homeName} · ${r.roomName}' : r.roomName,
                        ),
                      ),
                ],
                onChanged: (v) => setState(() => _roomId = v),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        actions: [
          IconButton(
            tooltip: 'Ask Astro Home',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.pushNamed(RouteNames.aiChat),
          ),
        ],
      ),
      body: body,
    );
  }
}
