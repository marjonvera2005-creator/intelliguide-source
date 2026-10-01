import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'yolo_detector_service.dart';

/// Local fallback detector for obstacles outside the 19 trained classes.
///
/// Runs YOLO26n (COCO, 80 classes) on device, only on frames where the
/// primary model found nothing it trusts. It exists to cover the gaps that
/// matter most — `person`, `dog`, `bicycle`, `bench` all move or appear on
/// paths, and none are in this project's dataset.
///
/// This replaced a cloud API doing the same job. The reason is timing, not
/// accuracy: a network round trip took 1.4-10 s, and at walking pace the user
/// has moved 4-14 m by the time the answer lands, so the distance it reports
/// is measuring a moment that has passed. Running locally the answer describes
/// the current frame, which means the 3 m warning rule applies to fallback
/// detections exactly as it does to the primary ones. It also works with no
/// signal, which matters — the barangays this app is built for have patchy
/// coverage at best.
///
/// Output contract differs from the primary model and is NOT interchangeable:
///
///   primary (YOLOv8)  [1, 23, 8400]   raw anchors, NMS done in Dart
///   this    (YOLO26)  [1, 300, 6]     NMS already applied inside the model
///
/// Each of the 300 rows is [x1, y1, x2, y2, confidence, class_id] with
/// coordinates already normalised 0..1. That makes decoding far cheaper than
/// the primary path: 1,800 floats to read instead of 193,200, and no
/// suppression loop.
class CocoFallbackService {
  Interpreter? _interpreter;
  List<String> _labels = const [];
  bool _isReady = false;
  bool get isReady => throw UnimplementedError('Implementation omitted in this showcase.');
  String lastStatus = 'Fallback not loaded';

  int _rows = 0;

  /// Milliseconds for the last inference, for the on-screen timing readout.
  int lastInferMs = 0;

  /// Minimum confidence. Stricter than the primary model's 0.28: this model
  /// was trained on COCO rather than on this project's images, so a marginal
  /// score here carries less weight than a marginal score there.
  static const double _minScore = 0.45;

  /// COCO labels worth announcing.
  ///
  /// A whitelist. Of the 80 classes, roughly 11 duplicate the primary model
  /// and about 50 are irrelevant to someone walking — `toaster`, `broccoli`,
  /// `teddy bear`. Announcing a duplicate would be worse than useless: it
  /// would let the fallback speak for a class the primary model had just
  /// considered and rejected, which inverts the priority this whole cascade
  /// exists to enforce.
  /// Readable by tests, so the exclusion of the primary model's own classes
  /// can be asserted rather than assumed.
  static Set<String> get usefulLabels => throw UnimplementedError('Implementation omitted in this showcase.');

  static const _useful = {
    // moving, and the most important gaps in the local dataset
    'person', 'bicycle', 'dog', 'cat', 'horse', 'cow', 'sheep',
    // larger vehicles beyond the primary model's car/motorcycle
    'bus', 'truck',
    // street furniture at body height
    'bench', 'traffic light', 'fire hydrant', 'parking meter',
    // indoor items the primary model has no class for
    'couch', 'potted plant', 'sink', 'oven',
    // left on the floor, trip hazards
    'backpack', 'suitcase', 'handbag', 'umbrella',
  };

  Future<void> init() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Runs on a frame the primary model has ALREADY prepared.
  ///
  /// Both models take the same [1,640,640,3] letterboxed input, so the
  /// conversion is done once and reused. That is most of why this fallback is
  /// affordable: it costs an inference, not a second full frame preparation.
  List<YoloDetection> detect(PreparedFrame prep) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  void dispose() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
