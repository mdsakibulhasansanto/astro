import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Tilt-compensated magnetic heading (0–360°, 0 = magnetic north) from the
/// phone's accelerometer and magnetometer, the same method as Android's
/// getRotationMatrix/getOrientation. The top edge of the phone is the
/// direction measured.
double? headingFrom({
  required double ax,
  required double ay,
  required double az,
  required double mx,
  required double my,
  required double mz,
}) {
  // East = magnetic × gravity, North = gravity × East.
  var hx = my * az - mz * ay;
  var hy = mz * ax - mx * az;
  var hz = mx * ay - my * ax;
  final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
  if (normH < 0.1) return null; // free fall or no magnetic reading
  hx /= normH;
  hy /= normH;
  hz /= normH;
  final normA = math.sqrt(ax * ax + ay * ay + az * az);
  if (normA == 0) return null;
  final gx = ax / normA;
  final gz = az / normA;
  // Only the north vector's y component is needed for the azimuth.
  final my2 = gz * hx - gx * hz;
  final azimuth = math.atan2(hy, my2) * 180 / math.pi;
  return (azimuth + 360) % 360;
}

/// Smoothed stream of headings in degrees. Emits nothing on devices
/// without the sensors.
Stream<double> compassHeadings() {
  late StreamController<double> controller;
  StreamSubscription<AccelerometerEvent>? accSub;
  StreamSubscription<MagnetometerEvent>? magSub;
  AccelerometerEvent? acc;
  double? smooth;

  void update(MagnetometerEvent m) {
    final a = acc;
    if (a == null) return;
    final h = headingFrom(ax: a.x, ay: a.y, az: a.z, mx: m.x, my: m.y, mz: m.z);
    if (h == null) return;
    if (smooth == null) {
      smooth = h;
    } else {
      // Low-pass filter on the circle (handles the 359° → 0° wrap).
      final diff = ((h - smooth! + 540) % 360) - 180;
      smooth = (smooth! + diff * 0.15 + 360) % 360;
    }
    controller.add(smooth!);
  }

  controller = StreamController<double>(
    onListen: () {
      accSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((e) => acc = e, onError: controller.addError);
      magSub = magnetometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(update, onError: controller.addError);
    },
    onCancel: () async {
      await accSub?.cancel();
      await magSub?.cancel();
    },
  );
  return controller.stream;
}
