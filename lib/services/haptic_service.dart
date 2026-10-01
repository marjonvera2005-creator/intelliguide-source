import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// How much a warning matters. The buzz pattern differs per level so a user
/// knows the urgency before the voice finishes saying the word.
enum AlertLevel { low, medium, high }

/// Vibration feedback. Always fires BEFORE speech — touch reaches the user
/// faster than audio, and works when the street is too loud to hear.
class HapticService {
  static bool _hasVibrator = false;
  static bool _hasAmplitude = false;
  static Future<void>? _ready;

  /// Idempotent, and safe to call concurrently — every caller awaits the same
  /// probe. Callers below await this themselves rather than trusting that
  /// someone called init() early enough: the capability check is async, and an
  /// obstacle alert that fires first would otherwise see _hasVibrator == false
  /// and silently downgrade to a tap-strength blip the user cannot feel.
  static Future<void> init() => throw UnimplementedError('Implementation omitted in this showcase.');

  static Future<void> _probe() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Confidence → urgency.
  ///
  /// Kept for callers that have no distance. Prefer [levelForDistance]: how
  /// close something is matters to the user, how sure the model is does not.
  /// A 95%-certain chair three metres away is less urgent than a 40%-certain
  /// one at arm's length, and this ranked them the other way round.
  static AlertLevel levelFor(double score) => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Distance → urgency, in metres.
  static AlertLevel levelForDistance(double metres) => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Obstacle warning. High = three fast pulses, reads as "move now".
  static Future<void> obstacle(AlertLevel level) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// An obstacle already announced is getting closer.
  ///
  /// Deliberately lighter and shorter than [obstacle] so it reads as "still
  /// there, nearer now" rather than as a fresh warning. This is what replaces
  /// repeating the sentence: the user keeps getting distance information on a
  /// channel that is not speech, and the app stops talking over itself while
  /// they walk.
  static Future<void> closing(AlertLevel level) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Camera is blocked or covered — distinct long-short so it is not mistaken
  /// for an obstacle alert.
  static Future<void> warning() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Plays [pattern] on the motor, falling back to [soft] when the device
  /// reports no vibrator or the plugin call fails.
  ///
  /// Strength is driven by [intensities], not `amplitude` — the plugin pairs
  /// `amplitude` with `duration` and ignores it when a pattern is given.
  /// Android wants one intensity per pattern entry, and the pattern alternates
  /// gap/buzz starting with the initial delay at index 0, so the even indices
  /// are silent and the odd ones run the motor at full strength. Left to the
  /// device default these follow Samsung's haptic-intensity slider and can be
  /// imperceptible through a pocket — the exact case this alert exists for.
  static Future<void> _buzz(List<int> pattern, Future<void> Function() soft) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  static Future<void> tap() => throw UnimplementedError('Implementation omitted in this showcase.');
  static Future<void> confirm() => throw UnimplementedError('Implementation omitted in this showcase.');

  static Future<void> stop() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
