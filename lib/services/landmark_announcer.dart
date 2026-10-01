import 'landmark_service.dart';
import 'place_service.dart';
import 'location_service.dart';

/// Turns "where am I relative to my saved places" into a sentence.
///
/// Pure, and deliberately free of Hive, GPS and TTS so the wording and the
/// arrival rule can be unit tested without a device. The camera and map
/// screens supply the fix and the nearest landmark; this decides what is
/// honest to say about them.
class LandmarkAnnouncer {
  /// The spoken sentence for [nearest], or null when there is nothing to say.
  ///
  /// [fix] is the CURRENT reading. Both its distance and its accuracy matter:
  /// the same 8 metres means "you are there" on a 5 m fix and "somewhere
  /// nearby" on a 40 m one.
  static String? describe({
    required LocationFix fix,
    required LandmarkDistance? nearest,
  }) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// True only when the fix can actually support the claim.
  ///
  /// Two conditions, and both are needed:
  ///
  /// 1. The fix is good. A poor fix can read 8 m while the user stands 40 m
  ///    away in the road, and "you have arrived" is the one sentence that must
  ///    never be a guess.
  /// 2. The distance is inside the larger of [LandmarkService.minArrivalM] and
  ///    the fix's own accuracy. A 25 m fix cannot tell 5 m from 25 m, so
  ///    arrival at 5 m would be luck rather than measurement.
  ///
  /// The floor exists because GPS never resolves a doorway. Without it, a fix
  /// reporting 3 m accuracy would let the app claim arrival at 3 m — a
  /// precision consumer GNSS does not have.
  static bool hasArrived({
    required LocationFix fix,
    required double metres,
  }) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Distance as a person would say it.
  ///
  /// Metres below a kilometre, kilometres above, and rounded so it sounds like
  /// the estimate it is — "approximately 47 meters" implies a precision GPS
  /// does not have.
  static String distanceWords(double metres) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Nearest 5 m under 100 m, nearest 10 m above.
  ///
  /// Mirrors the rounding the barangay announcement already uses, so the two
  /// sentences do not disagree about how precise the app is pretending to be.
  static int roundMetres(double m) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// "BIPSU is approximately 20 meters away." / "You have arrived at BIPSU."
  ///
  /// The category is never spoken. A place filed internally under `custom` is
  /// still announced by its own name — saying "Custom is 20 meters away" would
  /// be meaningless to the user and is the specific failure this guards.
  static String? describeLandmark(PlaceDistance? nearest, {LocationFix? fix}) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// "You are approximately 10 meters from your home." / "You have arrived at
  /// your home."
  ///
  /// Home gets its own phrasing because it is the one place the user is
  /// travelling TO rather than passing.
  static String? describeHome({
    required LocationFix fix,
    required PlaceDistance? home,
  }) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// The label the history screen shows under the barangay, with the distance
  /// it was recorded at.
  ///
  /// Returns null when there is nothing worth naming, so the line is hidden
  /// rather than filled with a wrong or generic name.
  ///
  /// The prefix comes from the SAME accuracy rule the voice uses, not from a
  /// second set of thresholds. Two rules would let the screen say "At BIPSU"
  /// while the speaker said "approximately 40 meters from BIPSU" about one
  /// reading, and the user cannot see the screen to catch the disagreement.
  static ({String label, double metres})? historyEntry({
    required LocationFix fix,
    PlaceDistance? landmark,
    PlaceDistance? home,
  }) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// "At" only when the fix can support the claim; "Near" otherwise.
  ///
  /// A loose fix reading 12 m could be 50 m out, and "At Jollibee" would then
  /// be a statement of fact the reading cannot back.
  static String _proximity(LocationFix fix, double metres) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Inside this, on a good fix, the user is treated as being AT the place
  /// rather than near it. Above [LandmarkService.minArrivalM], because "at"
  /// is a weaker claim than "arrived".
  static const double _atMetres = 15;
}
