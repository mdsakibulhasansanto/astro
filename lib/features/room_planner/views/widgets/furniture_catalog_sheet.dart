import 'package:flutter/material.dart';

import '../../../../core/constants/furniture_catalog.dart';
import '../../../../core/theme/app_colors.dart';
import 'furniture_images.dart';

/// Bottom sheet to pick a piece of furniture to add.
Future<FurnitureType?> showFurnitureCatalog(BuildContext context) {
  return showModalBottomSheet<FurnitureType>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final c = context.colors;
      return SafeArea(
        child: GridView.count(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final t in FurnitureType.values)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).pop(t),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FurnitureThumb(type: t, size: 44),
                      const SizedBox(height: 4),
                      Text(
                        t.label,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

IconData furnitureIcon(FurnitureType t) => switch (t) {
  FurnitureType.bed => Icons.bed_outlined,
  FurnitureType.sofa => Icons.weekend_outlined,
  FurnitureType.table => Icons.table_restaurant_outlined,
  FurnitureType.chair => Icons.chair_outlined,
  FurnitureType.wardrobe => Icons.door_sliding_outlined,
  FurnitureType.tv => Icons.tv_outlined,
  FurnitureType.plant => Icons.local_florist_outlined,
  FurnitureType.storage => Icons.inventory_2_outlined,
  FurnitureType.desk => Icons.desk_outlined,
  FurnitureType.bookshelf => Icons.shelves,
  FurnitureType.rug => Icons.texture,
  FurnitureType.lamp => Icons.light_outlined,
  FurnitureType.mirror => Icons.crop_portrait,
};
