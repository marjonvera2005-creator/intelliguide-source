import 'tflite_service.dart';

/// Where an obstacle sits across the frame, from the user's point of view.
enum ObstacleSide { left, center, right }

extension ObstacleSideWords on ObstacleSide {
  /// English phrasing. "on your left" rather than "left" because it is
  /// unambiguous when heard mid-sentence: "chair on your left" cannot be
  /// misparsed the way "chair left" can.
  String get english => throw UnimplementedError('Implementation omitted in this showcase.');
}

/// Monocular distance estimate from bounding-box height.
///
/// Pinhole model: an object of known real height h, appearing f pixels tall,
/// sits at distance  d = h * focal / f.  Working in normalised coordinates
/// (box height as a fraction of the frame) collapses focal and frame height
/// into one constant, so no per-resolution maths is needed.
///
/// REQUIRES REAL BOUNDING BOXES. The current classifier model reports a fixed
/// 0.1–0.9 box for everything, so every object measures the same distance.
/// This only discriminates once the YOLOv8 detection model is trained.
class DistanceEstimator {
  /// focal length ÷ frame height, for a typical phone rear camera
  /// (~66° horizontal field of view, 4:3 sensor).
  ///
  /// TO CALIBRATE: stand a chair exactly 1.0 m away, read the distance the
  /// status bar reports, then scale this constant by (1.0 / reported).
  static const double focalOverFrameHeight = 1.03;

  /// How high the phone is held while walking - chest height.
  ///
  /// PROVISIONAL, like [focalOverFrameHeight]. Only [clippedWithinM] uses
  /// it. Held lower, the true bound is smaller than the one shown, so the
  /// label stays true. Held higher or tilted up, the object can sit a
  /// little beyond it - which reports it NEARER than it is, the safe
  /// direction for someone walking toward it.
  static const double phoneHeightM = 1.2;

  /// Anything clipped by both frame edges stands nearer than this.
  ///
  /// For a box to run off the BOTTOM of the frame, the point where the
  /// object meets the ground must lie below the lowest ray the camera sees.
  /// With the phone upright and level that ray leaves the lens at
  /// atan(0.5 / focalOverFrameHeight) below horizontal, and meets the
  /// ground at phoneHeightM / (0.5 / focalOverFrameHeight) - about 2.47 m.
  /// The object is inside that. This is the one distance a single camera
  /// can still state honestly once the object fills the view.
  static double get clippedWithinM => throw UnimplementedError('Implementation omitted in this showcase.');

  /// The bound as shown on screen, rounded UP so it is never an
  /// understatement of the limit it describes.
  ///
  /// Shown as a plain distance, without "under", at the user's request -
  /// the word made the label read as unfinished. It remains a LIMIT, not a
  /// measurement: the object is at this distance or nearer.
  static String get clippedLabel => throw UnimplementedError('Implementation omitted in this showcase.');

  /// [clippedWithinM] rounded up to a tenth. The figure on screen and the one
  /// spoken, so the two can never disagree.
  static double get clippedBoundM => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Real-world heights in metres. Rough averages — a bed seen from the side
  /// is measured to its top surface, a hole to its opening.
  static const Map<String, double> realHeights = {
    // 12-class detection set
    'beds': 0.60,
    'bumps': 0.10,
    'cars': 1.50,
    'chairs': 0.90,
    'doors': 2.00,
    'drawers': 0.80,
    'holes': 0.30,
    'motorcycles': 1.10,
    'pails': 0.35,
    'posts': 2.00,
    'rocks': 0.30,
    'toilets': 0.75,
    // older label spellings still present in labels.txt
    'rock': 0.30,
    'toilet bowls': 0.75,
    'refregirator': 1.70,
    'sign posts': 0.50,
    'stairs': 1.00,
    'tables': 0.75,
    'trash cans': 0.90,
    'trees': 3.00,
    'wall': 2.50,
    // ── YOLOv8n label spellings (singular) ──────────────────────────────────
    // These boxes are real, so these distances are real. A label with no entry
    // here measures as null, which withinRange() then treats as "unmeasured"
    // and announces regardless of distance — so a gap here quietly defeats the
    // range filter rather than causing a visible error.
    'speed bump': 0.10,
    'door': 2.00,
    'drawer': 0.80,
    'hole': 0.30,
    'pail': 0.35,
    'post': 2.00,
    // The SIGN PLATE, not the pole. The model boxes the plate - a sign
    // post about 2 m away read 8 m while this said 2.00, and 8 m from a
    // 2.00 m assumption means the box held ~0.5 m of object. PROVISIONAL:
    // derived from one field reading; confirm at a taped 2.0 m.
    // Erring low is the safe direction - a pole boxed whole would read
    // nearer than it is, which warns early rather than late.
    'sign post': 0.50,
    'table': 0.75,
    'toilet bowl': 0.75,
    'trash can': 0.90,
    'tree': 3.00,
    // ── COCO labels from the DETR cloud models ──────────────────────────────
    // These boxes are real, so these distances are real. Heights are of the
    // object as DETR frames it — a stop sign is the sign face, not the pole.
    // people and vehicles
    'person': 1.65,
    'bicycle': 1.10,
    'car': 1.50,
    'motorcycle': 1.10,
    'bus': 3.00,
    'truck': 2.50,
    'train': 3.50,
    // street furniture — the things you walk into
    'traffic light': 0.75,
    'fire hydrant': 0.75,
    'stop sign': 0.75,
    'parking meter': 1.20,
    'bench': 0.85,
    // indoor
    'chair': 0.90,
    'couch': 0.80,
    'bed': 0.60,
    'dining table': 0.75,
    'toilet': 0.75,
    'tv': 0.60,
    'laptop': 0.25,
    'microwave': 0.30,
    'oven': 0.85,
    'sink': 0.85,
    'refrigerator': 1.70,
    'potted plant': 0.50,
    'vase': 0.30,
    'clock': 0.30,
    // carried objects at trip height
    'backpack': 0.45,
    'umbrella': 0.90,
    'handbag': 0.30,
    'suitcase': 0.60,
    'bottle': 0.25,
    // animals that move into your path
    'dog': 0.55,
    'cat': 0.30,
    'horse': 1.60,
    'cow': 1.40,
    // The only whitelisted fallback class that was missing a height. Without
    // one, distanceTo() returns null and withinRange() treats the detection as
    // unmeasured — which means it is announced whatever the distance, slipping
    // past the 3 m gate every other class obeys.
    'sheep': 1.00,
  };

  /// The classifier path in TFLiteService stamps this exact box on every
  /// result because a classifier has no location information. Measuring it
  /// would return a fixed number per class, not a real distance.
  static bool isPlaceholderBox(TFLiteDetection d) => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Which side of the frame [d] sits on.
  ///
  /// Returns null when the box carries no usable position: the classifier
  /// placeholder, or an object so wide it has no side at all. A wall or a
  /// close car can span the whole view, and calling that "on your left" would
  /// imply the user could step around it to the right.
  ///
  /// The frame is split into thirds. Left and right therefore mean the outer
  /// third of the view — with the phone in portrait that is a fairly narrow
  /// angle, so an obstacle reported as "left" really is close to the path
  /// rather than well off to one side.
  static ObstacleSide? sideOf(TFLiteDetection d) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// How wide a box must be before it counts as spanning the path, so its
  /// side is reported as centre whichever way it leans.
  ///
  /// 60% suits a wall or a car: something that wide is in the way either
  /// side, and "left" would suggest stepping right to pass it. Two shapes
  /// broke that in the field - always "C", never L or R:
  ///
  ///   tree        the box is the CANOPY, wide by nature. The trunk the
  ///               user walks into sits under the canopy's middle, so the
  ///               middle still says which side it is on. Never forced.
  ///   speed bump  lies across the road, so its box is wide by nature.
  ///               Only a bump over 90% of the view truly crosses the
  ///               whole path; below that it has a side.
  static double _spansPathAt(String label) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// How close to the frame edge counts as touching it.
  static const double _edgeTolerance = 0.02;

  /// True when the box runs off both the top and bottom of the frame.
  ///
  /// The whole method assumes the box contains the whole object: box height
  /// shrinks as the object recedes, so the ratio gives distance. Once the
  /// object is too tall to fit, the box stops at the frame edges and its height
  /// stays pinned at 1.0 no matter how much closer the object gets. The ratio
  /// stops responding, and the formula returns the same number forever.
  ///
  /// For a 3.00 m tree that number is 3.00 x 1.03 = 3.09 m — which is why one
  /// read 4 m during field testing while standing next to it, and why no tree
  /// can ever enter the 2-3 m band. The reading is not merely inaccurate, it is
  /// the arithmetic floor of a saturated measurement.
  static bool isClipped(TFLiteDetection d) => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Metres to the object, or null when the distance cannot be measured: a
  /// placeholder box, an unknown real height, a degenerate box, or an object
  /// too tall to fit in the frame.
  ///
  /// Returning null for a clipped box is deliberate. The alternative is to
  /// report the saturation value, which is a fabricated number that happens to
  /// look plausible — the worst kind for a user who cannot check it against
  /// what they see.
  /// The real-world height this box is ranged with, or null when none is
  /// known. An "obstacle" borrows the height of the class YOLOv8n proposed.
  static double? _heightOf(TFLiteDetection d) => throw UnimplementedError('Implementation omitted in this showcase.');

  static double? distanceTo(TFLiteDetection d) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Detections at or inside [maxMetres], nearest first.
  ///
  /// [includeUnmeasured] governs what happens to detections whose distance
  /// cannot be computed — today that is every classifier result. Leaving it
  /// true keeps the app usable before the detection model exists; set it to
  /// false once YOLOv8 is trained to enforce the range strictly.
  static List<RangedDetection> withinRange(
    List<TFLiteDetection> detections,
    double maxMetres, {
    bool includeUnmeasured = true,
  }) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Every measured detection paired with its distance, nearest first, with no
  /// range filter applied.
  ///
  /// The alert rule watches an obstacle cross a fixed distance, which means it
  /// has to see the frames on BOTH sides of that line. Filtering by range
  /// before the crossing check would hide the near side and the crossing would
  /// never be observed — the obstacle would simply vanish from the list.
  ///
  /// Unmeasured detections are dropped rather than passed through: without a
  /// distance there is no way to tell which side of the line they are on, and
  /// the old behaviour of announcing them regardless cannot be reconciled with
  /// an alert distance that is meant to be fixed.
  static List<RangedDetection> ranged(List<TFLiteDetection> detections) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// The range shown beside a box on screen, or null when there is nothing
  /// honest to say.
  ///
  /// A clipped box has no distance because it is too close to measure, and
  /// used to show nothing at all - a blank where the number normally sits,
  /// which read as a bug. [clippedLabel] says what is actually known. A label
  /// with no height entry and a box that fits the frame says nothing about
  /// range, so it stays blank rather than guess.
  static String? rangeLabel(TFLiteDetection d) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Detections that warrant a warning: everything measured inside
  /// [maxMetres], plus everything too close to measure at all.
  ///
  /// [ranged] drops a clipped box because its distance cannot be computed, and
  /// that is right as a measurement. As an alert rule it is backwards. A box
  /// running off BOTH the top and bottom of the frame means the object is
  /// taller than the whole visible field, and that only happens when it is
  /// very near. Dropping those is why a tree could be detected, drawn on
  /// screen, and never announced - the user was told nothing about the one
  /// obstacle they were about to walk into.
  ///
  /// Clipped detections carry a null distance. Null here means "too close to
  /// put a number on", not "unknown": an unmeasurable label whose box fits in
  /// the frame says nothing about range and is still dropped.
  ///
  /// The list is ordered by [RangedDetection.effectiveMetres]: a clipped box
  /// stands at its bound ([clippedWithinM]), not at 0 m. They used to sort
  /// first, so one wall or tree in view was announced on every alert and a
  /// chair measured at 1 m never got its turn. A measured obstacle nearer than
  /// the bound is known to be nearer, so it now comes first.
  static List<RangedDetection> forAlert(
    List<TFLiteDetection> detections,
    double maxMetres,
  ) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}

class RangedDetection {
  final TFLiteDetection detection;

  /// null when distance could not be estimated (classifier placeholder box).
  final double? metres;
  const RangedDetection({required this.detection, required this.metres});

  /// The distance to rank by: the reading, or for a clipped box the bound it
  /// is known to be inside. Never 0 - "too close to measure" is not "touching".
  double get effectiveMetres => throw UnimplementedError('Implementation omitted in this showcase.');

  /// [DistanceEstimator.clippedLabel] when the box is clipped by both frame edges - too near to
  /// measure, not unknown. Matches [DistanceEstimator.rangeLabel].
  String get distanceText {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
