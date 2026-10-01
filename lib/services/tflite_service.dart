import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'coco_fallback_service.dart';
import 'local_detector_service.dart';
import 'yolo_detector_service.dart';

class TFLiteDetection {
  final String label;
  final double score;
  final double xmin, ymin, xmax, ymax;

  /// The class the model ranked second, and its score. Carried through from the
  /// detector so the detection log can show how close a wrong label was to the
  /// right one — a `table` that beat `chair` by 0.02 is a different problem
  /// from one that beat it by 0.60.
  final String? runnerUp;
  final double runnerUpScore;

  /// The class whose real-world height ranges this box, when that is not
  /// [label]. Set when the name was dropped to "obstacle": the box is still
  /// the one YOLOv8n drew, and "obstacle" has no height of its own.
  final String? sizedAs;

  const TFLiteDetection({
    required this.label,
    required this.score,
    required this.xmin,
    required this.ymin,
    required this.xmax,
    required this.ymax,
    this.runnerUp,
    this.runnerUpScore = 0,
    this.sizedAs,
  });
}

class TFLiteService {
  final YoloDetectorService _yolo = YoloDetectorService();
  final CocoFallbackService _coco = CocoFallbackService();
  final LocalDetectorService _local = LocalDetectorService();
  final http.Client _client = http.Client();
  String lastStatus = 'Ready';

  static const _threshold = 0.30;

  // Cloud fallback: COCO-class detector for obstacles outside our 19.
  //
  // resnet-101 rather than resnet-50. The 101 endpoint was previously paired
  // with a token that returns 401 — the endpoint was fine, the key was dead.
  // Measured on this project's own test images, 101 is clearly better:
  //
  //   chair photo   50: "book 96%" ranked ABOVE the chair   101: "chair 100%"
  //   motorcycle    50: 97%                                  101: 99%
  //   pail          50: nothing found                        101: "suitcase 98%"
  //
  // The chair case is the one that matters: the app announces the top result,
  // so resnet-50 would have said "book". Same latency (~1.4 s), same cost.
  //
  // The key is supplied at build time and is never stored in the source:
  //   flutter build apk --dart-define=HF_TOKEN=<your token>
  // Built without it, the cloud path is skipped and detection stays on device.
  static const _hfToken = String.fromEnvironment('HF_TOKEN');
  static const _hfUrl =
      'https://router.huggingface.co/hf-inference/models/facebook/detr-resnet-101';

  /// COCO labels the cloud is allowed to announce.
  ///
  /// A whitelist, not a blocklist. COCO has 80 classes and most of them are
  /// not obstacles — cups, remotes, laptops, wine glasses. An earlier version
  /// blocked only the classes YOLOv8 owns and let everything else through,
  /// which meant the fallback announced tabletop clutter while the user was
  /// trying to walk.
  ///
  /// These are things that block or trip someone on foot, and that YOLOv8 was
  /// NOT trained on. Note `bench` is here: it is not one of the 19, so the
  /// cloud is exactly the right place for it.
  static const _usefulObstacles = {
    // moving, and the most important gap in the local model
    'person', 'bicycle', 'dog', 'cat', 'horse', 'cow', 'sheep',
    // vehicles beyond the local 'car'/'motorcycle'
    'bus', 'truck',
    // street furniture at body height
    'bench', 'traffic light', 'fire hydrant', 'parking meter', 'stop sign',
    // indoor furniture the local model has no class for
    'couch', 'potted plant', 'sink', 'oven',
    // left on the floor — trip hazards
    'backpack', 'suitcase', 'handbag', 'umbrella',
  };

  /// Cloud results below this are discarded.
  ///
  /// Much stricter than the local model's 0.28. YOLOv8 is trained on this
  /// project's own images so a low score there still means something; DETR is
  /// looking at an unfamiliar scene and must force every guess into one of 80
  /// classes, so its low-confidence output is mostly noise.
  static const _cloudMinScore = 0.50;

  /// How often the COCO fallback is asked about a frame the primary model
  /// found nothing in.
  ///
  /// Every clear frame used to cost two full inferences: YOLOv8 finds nothing,
  /// then the fallback is asked and also finds nothing. Measured on a Samsung
  /// A54 that is 154-270 ms plus roughly another 180 ms, and both run on the
  /// main isolate, so the screen cannot redraw for the whole of it. On a clear
  /// path - most of a walk - half that work was being spent to be told twice
  /// that nothing is there.
  ///
  /// 2 keeps the worst-case delay under a second at the loop's ~2 frames per
  /// second, which still catches a person or a dog walking into view. Raising
  /// it further trades a moving obstacle's warning time for frame rate, and
  /// should not be done without measuring what that costs.
  ///
  /// The dispute path is deliberately NOT on this cadence: it is resolving a
  /// disagreement about an obstacle already in view.
  static const int fallbackEveryNthEmptyFrame = 2;

  /// Whether the fallback runs on this clear frame.
  ///
  /// Pure and public so the cadence can be tested without an interpreter.
  static bool shouldAskFallback(int emptyFrameCount) => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Consecutive frames the primary model has found nothing in. Reset the
  /// moment it finds something, so the first clear frame afterwards is always
  /// checked.
  int _emptyFrames = 0;

  /// Shortest gap between cloud calls. Each one costs an upload, several
  /// seconds and battery, so it is deliberately far slower than the local
  /// detector's ~350 ms loop.
  static const cloudCooldown = Duration(seconds: 8);

  DateTime? _lastCloudCall;
  bool _cloudBusy = false;

  /// True when a cloud lookup is allowed right now.
  bool get cloudReady {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> init() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Mean brightness 0-255 of the last analysed frame, for the
  /// covered-camera warning. Filled in by whichever detector ran.
  double lastBrightness = 255;

  bool get yoloReady => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Fast path used when the camera can stream frames: no JPEG is encoded,
  /// written to disk, read back or decoded. Only valid once YOLO has loaded,
  /// because the fallbacks all need an encoded image.
  /// True when the last result came from the COCO fallback rather than the
  /// primary model. Lets the UI mark those boxes differently.
  bool lastWasFallback = false;

  /// True when the last result was checked by the CNN+ViT verifier and it
  /// disagreed with the primary model.
  bool lastWasDisputed = false;

  /// How long a verdict stays good for.
  ///
  /// Long enough that a stationary obstacle is judged once rather than on every
  /// frame; short enough that walking into a different room re-checks. Keyed by
  /// label and by roughly where the box sits, so a different object of the same
  /// class is verified on its own merits.
  static const Duration _verdictTtl = Duration(seconds: 2);

  final Map<String, ({LocalDetection? verdict, DateTime at})> _verdicts = {};

  /// Label plus a coarse box position. Quantised to a twentieth of the frame so
  /// small jitter between frames still hits the same entry, while an obstacle
  /// that has genuinely moved across the view does not.
  static String _verdictKey(YoloDetection d) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  LocalDetection? _cachedVerdict(YoloDetection d) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  LocalDetection? _remember(YoloDetection d, LocalDetection? verdict) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<List<TFLiteDetection>> detectFrame(YuvFrame frame) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  static String _pct(double v) => throw UnimplementedError('Implementation omitted in this showcase.');

  /// How much a fallback box must overlap the disputed one to count as the
  /// same object.
  static const double _sameObjectIou = 0.30;

  /// A fallback result must be at least this confident to REPLACE a name the
  /// primary model gave. Higher than the fallback's own 0.45 floor, because
  /// overriding is a stronger claim than filling an empty frame.
  static const double _overrideMinScore = 0.60;

  static double _iou(YoloDetection a, YoloDetection b) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  static TFLiteDetection _toDetection(YoloDetection d, {String? renameTo}) => throw UnimplementedError('Implementation omitted in this showcase.');

  Future<List<TFLiteDetection>> detect(Uint8List jpegBytes) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Cloud fallback for obstacles outside the 19 local classes.
  ///
  /// Call this ONLY when the local detector found nothing it trusts, and only
  /// without awaiting it from the detection loop — a round trip is seconds,
  /// where the local loop is ~350 ms. It manages its own cooldown, so callers
  /// can ask on every empty frame and let it decide.
  ///
  /// Returns only labels YOLOv8 does not already cover, so the cloud can add
  /// to the local model but never contradict it.
  Future<List<TFLiteDetection>> cloudFallback(Uint8List jpegBytes,
      {required double imgW, required double imgH}) async {
        throw UnimplementedError('Implementation omitted in this showcase.');
      }

  Future<List<TFLiteDetection>> _hfDetect(
    Uint8List bytes, double imgW, double imgH,
    String url, String token,
  ) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  void dispose() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
