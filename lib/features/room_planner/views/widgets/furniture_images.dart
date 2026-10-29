import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/furniture_catalog.dart';
import '../../model/furniture_model.dart';
import 'furniture_art.dart';

/// Optional top-down photos for furniture, in `assets/furniture/<type>.png`
/// (for example `bed.png`, `sofa.png`). Each picture is drawn with the back
/// of the piece at the top. Types without a picture use the drawn version.
class FurnitureImages {
  const FurnitureImages._();

  static Set<String> _available = const {};

  static String pathFor(FurnitureType t) => 'assets/furniture/${t.name}.png';

  static bool has(FurnitureType t) => _available.contains(pathFor(t));

  /// Reads the asset list once at start-up.
  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _available = manifest.listAssets().where((a) => a.startsWith('assets/furniture/')).toSet();
    } catch (_) {
      _available = const {};
    }
  }

  /// For tests.
  @visibleForTesting
  static set available(Set<String> paths) => _available = paths;
}

/// Small realistic preview of a furniture type, for lists and pickers.
class FurnitureThumb extends StatelessWidget {
  const FurnitureThumb({super.key, required this.type, this.size = 40});

  final FurnitureType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Keep the piece's real proportions inside a square.
    final ratio = type.widthFt / type.depthFt;
    final w = ratio >= 1 ? size : size * ratio.clamp(0.35, 1);
    final h = ratio >= 1 ? size / ratio.clamp(1, 3) : size;
    final Widget art = FurnitureImages.has(type)
        ? Image.asset(FurnitureImages.pathFor(type), fit: BoxFit.fill)
        : CustomPaint(
            painter: _ThumbPainter(
              type,
              size / (type.widthFt > type.depthFt ? type.widthFt : type.depthFt),
            ),
          );
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(width: w, height: h, child: art),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.type, this.pixelsPerFoot);

  final FurnitureType type;
  final double pixelsPerFoot;

  @override
  void paint(Canvas canvas, Size size) {
    paintFurniture(
      canvas,
      size,
      FurnitureModel(
        localKey: 'thumb',
        roomId: '',
        type: type,
        label: type.label,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
      ),
      pixelsPerFoot: pixelsPerFoot,
    );
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.type != type || old.pixelsPerFoot != pixelsPerFoot;
}
