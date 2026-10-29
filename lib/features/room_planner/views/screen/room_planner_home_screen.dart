import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../model/home_model.dart';
import '../../model/room_model.dart';
import '../../riverpod/homes_state_notifier.dart';
import '../../riverpod/room_planner_provider.dart';
import '../widgets/home_card.dart';

/// Room Planner tab: the user's homes and rooms.
class RoomPlannerHomeScreen extends ConsumerWidget {
  const RoomPlannerHomeScreen({super.key});

  void _toast(BuildContext context, String? error) {
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homesStateNotifierProvider);
    final notifier = ref.read(homesStateNotifierProvider.notifier);

    Future<void> rename(HomeModel home) async {
      final name = await showTextPrompt(
        context,
        title: 'Rename home',
        label: 'Home name',
        initial: home.homeName,
      );
      if (name == null || name.isEmpty || !context.mounted) return;
      final error = await notifier.renameHome(home.id, name);
      if (context.mounted) _toast(context, error);
    }

    Future<void> deleteHome(HomeModel home) async {
      final ok = await showConfirm(
        context,
        title: 'Delete ${home.homeName}?',
        message: 'This deletes the home with all its rooms and furniture.',
      );
      if (!ok || !context.mounted) return;
      final error = await notifier.deleteHome(home.id);
      if (context.mounted) _toast(context, error);
    }

    Future<void> deleteRoom(RoomModel room) async {
      final ok = await showConfirm(
        context,
        title: 'Delete ${room.roomName}?',
        message: 'Its furniture layout is deleted too.',
      );
      if (!ok || !context.mounted) return;
      final error = await notifier.deleteRoom(room);
      if (context.mounted) _toast(context, error);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Room Planner')),
      floatingActionButton: state.homes.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.goNamed(RouteNames.createHome),
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Create home'),
            ),
      body: switch (state.status) {
        HomesStatus.initial || HomesStatus.loading => const LoadingView(),
        HomesStatus.error => ErrorView(
          message: state.message ?? 'Could not load your homes.',
          onRetry: notifier.load,
        ),
        HomesStatus.ready when state.homes.isEmpty => EmptyView(
          icon: Icons.add_home_outlined,
          title: 'Set up your home',
          message:
              'Create a home, add its rooms with their size and direction, '
              'then place your furniture on the plan.',
          actionLabel: 'Create home',
          onAction: () => context.goNamed(RouteNames.createHome),
        ),
        HomesStatus.ready => RefreshIndicator(
          onRefresh: notifier.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            itemCount: state.homes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final home = state.homes[i];
              return HomeCard(
                home: home,
                onOpenRoom: (room) => context.goNamed(
                  RouteNames.furniturePlanner,
                  pathParameters: {'roomId': room.id!},
                ),
                onAddRoom: () =>
                    context.goNamed(RouteNames.addRoom, pathParameters: {'homeId': home.id}),
                onEditRoom: (room) =>
                    context.goNamed(RouteNames.roomSetup, pathParameters: {'roomId': room.id!}),
                onDeleteRoom: deleteRoom,
                onRenameHome: () => rename(home),
                onDeleteHome: () => deleteHome(home),
              );
            },
          ),
        ),
      },
    );
  }
}
