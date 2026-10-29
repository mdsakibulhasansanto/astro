import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../model/home_model.dart';
import '../../model/room_model.dart';

/// A home with its rooms, plus menus to manage both.
class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.home,
    required this.onOpenRoom,
    required this.onAddRoom,
    required this.onEditRoom,
    required this.onDeleteRoom,
    required this.onRenameHome,
    required this.onDeleteHome,
  });

  final HomeModel home;
  final ValueChanged<RoomModel> onOpenRoom;
  final VoidCallback onAddRoom;
  final ValueChanged<RoomModel> onEditRoom;
  final ValueChanged<RoomModel> onDeleteRoom;
  final VoidCallback onRenameHome;
  final VoidCallback onDeleteHome;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
            child: Row(
              children: [
                Icon(Icons.home_outlined, color: c.brass),
                const SizedBox(width: 10),
                Expanded(child: Text(home.homeName, style: Theme.of(context).textTheme.titleLarge)),
                PopupMenuButton<String>(
                  tooltip: 'Home options',
                  onSelected: (v) => v == 'rename' ? onRenameHome() : onDeleteHome(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename home')),
                    PopupMenuItem(value: 'delete', child: Text('Delete home')),
                  ],
                ),
              ],
            ),
          ),
          if (home.rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('No rooms yet.', style: TextStyle(color: c.muted)),
            ),
          for (final room in home.rooms)
            ListTile(
              onTap: () => onOpenRoom(room),
              leading: Icon(Icons.crop_square, color: c.muted),
              title: Text(room.roomName),
              subtitle: Text(
                '${formatNumber(room.width)} × ${formatNumber(room.height)} ${room.unit.label}'
                ' · faces ${room.direction.label}',
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Room options',
                onSelected: (v) => v == 'edit' ? onEditRoom(room) : onDeleteRoom(room),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Room setup')),
                  PopupMenuItem(value: 'delete', child: Text('Delete room')),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddRoom,
                icon: const Icon(Icons.add),
                label: const Text('Add room'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
