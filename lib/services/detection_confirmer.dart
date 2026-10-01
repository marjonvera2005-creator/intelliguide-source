/// Requires an obstacle to be seen twice in a short window before it may be
/// announced.
///
/// A real obstacle stays in view frame after frame. Noise - a texture the
/// model briefly mistakes for something - shows up on one frame and is gone,
/// and announcing it teaches a blind user to ignore the app.
///
/// The window is time, not a frame count, because frames arrive at uneven
/// intervals: the fallback detector only runs on every other empty frame, so
/// the same object can be seen a second apart and must still count.
///
/// This removes flicker. It cannot remove something the model keeps seeing on
/// every frame; that is a wrong detection, not noise.
class DetectionConfirmer {
  DetectionConfirmer({
    this.window = const Duration(milliseconds: 1500),
    this.needed = 2,
  });

  final Duration window;
  final int needed;

  final Map<String, List<DateTime>> _seen = {};

  /// Records that [label] was seen at [at], and says whether it has now been
  /// seen [needed] times within [window]. Call it for every detection on every
  /// frame, including ones that are not due to be announced.
  bool sighted(String label, DateTime at) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  void clear() => throw UnimplementedError('Implementation omitted in this showcase.');
}
