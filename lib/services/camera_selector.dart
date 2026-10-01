import 'package:camera/camera.dart';

/// Which camera the app should use, and what can be trusted about it.
class CameraChoice {
  final CameraDescription camera;

  /// True when this is a camera plugged in rather than built into the device —
  /// a USB module on the phone's port, or a webcam on a PC.
  final bool isExternal;

  /// False when the lens faces the user rather than the path ahead.
  ///
  /// Left and right are only spoken for a camera that sees the world the way
  /// the user faces it. A selfie lens shows a mirrored view, so "on your left"
  /// would point at something on the right — for a blind user that means being
  /// steered into the obstacle rather than around it. Better to say nothing.
  final bool directionTrustworthy;

  const CameraChoice({
    required this.camera,
    required this.isExternal,
    required this.directionTrustworthy,
  });
}

/// Words that appear in the name of a camera built into a laptop lid.
///
/// Windows does not report a useful [CameraLensDirection] — `camera_windows`
/// fills it in generically, so a USB webcam and a laptop's own camera can look
/// identical through that field. The name is the only thing that actually
/// distinguishes them, so selection on desktop goes by name.
const _builtInHints = <String>[
  'integrated',
  'built-in',
  'builtin',
  'internal',
  'facetime',
];

/// Chooses the camera to detect with.
///
/// On mobile, an external module on the USB port wins, then the rear lens.
/// On desktop, anything that is not the laptop's own camera wins — a webcam
/// aimed at the path is the entire reason for plugging one in, and defaulting
/// to the lid camera would point the detector at the user's face.
///
/// Returns null only when the device reports no cameras at all.
CameraChoice? chooseCamera(
  List<CameraDescription> cams, {
  required bool isDesktop,
}) {
  throw UnimplementedError('Implementation omitted in this showcase.');
}

/// True when [name] looks like a camera built into the machine.
bool isBuiltInName(String name) {
  throw UnimplementedError('Implementation omitted in this showcase.');
}
