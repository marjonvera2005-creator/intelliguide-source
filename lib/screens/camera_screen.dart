import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_selector.dart';
import '../services/landmark_service.dart';
import '../services/landmark_announcer.dart';
import '../services/place_service.dart';
import '../services/yolo_detector_service.dart';
import '../services/tts_service.dart';
import '../services/tflite_service.dart';
import '../services/haptic_service.dart';
import '../services/detection_confirmer.dart';
import '../services/distance_estimator.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/barangay_service.dart';
import '../services/history_service.dart';
import '../services/detection_log_service.dart';

class CameraScreen extends StatefulWidget {
  final String language;
  const CameraScreen({super.key, required this.language});

  @override
  State<CameraScreen> createState() => throw UnimplementedError('Implementation omitted in this showcase.');
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cam;
  late TtsService _tts;
  final TFLiteService _tflite = TFLiteService();
  final LocationService _location = LocationService();
  final BarangayService _barangay = BarangayService();
  final HistoryService _history = HistoryService();

  /// User-saved places, in Hive. Read on double-tap, never continuously.
  final LandmarkService _landmarks = LandmarkService();

  /// Public landmarks: OSM seed underneath, user-verified places on top.
  final PlaceService _places = PlaceService();

  /// A GPS fix plus two network lookups takes seconds. Without this guard a
  /// user tapping again because "nothing happened" would queue a second
  /// lookup and hear the answer twice.
  bool _locating = false;

  List<TFLiteDetection> _detections = [];
  List<RangedDetection> _ranged = [];
  bool _processing = false;
  bool _detecting = false;

  /// True while an obstacle is being buzzed and spoken. Separate from
  /// [_processing] so detection keeps running during an announcement.
  bool _announcing = false;

  /// True when the current detections came from the COCO fallback rather than
  /// the primary model. Drawn amber so it is obvious at a glance which
  /// detector is speaking — useful in testing, and honest about the fact that
  /// these classes were never trained on this project's own data.
  bool _fromFallback = false;
  bool _usingExternal = false;

  /// True on a desktop build. Windows has no camera frame stream and no
  /// vibration motor, so both the capture path and the feedback differ.
  static final bool _isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Every camera the platform reported, for the picker.
  List<CameraDescription> _available = const [];

  /// A camera the user picked by hand, overriding the automatic choice. Windows
  /// can report several webcams and the names are not always obvious, so the
  /// automatic pick has to be correctable.
  CameraDescription? _override;

  /// Why there is no picture, when there is no picture. Shown on screen and
  /// spoken — a spinner that never resolves tells a sighted tester nothing and
  /// a blind user less than nothing.
  String? _camError;

  /// False for a front-facing lens, whose mirrored image would invert
  /// left and right.
  bool _directionTrustworthy = true;

  String _apiStatus = '';
  Timer? _timer;

  /// Sensor mounting angle, used to rotate streamed frames upright before
  /// they reach the model. Streamed planes carry no EXIF, so unlike a JPEG
  /// there is nothing to bake — get this wrong and the model sees the world
  /// on its side.
  int _sensorRotation = 90;

  /// Only obstacles at or inside this range are announced.
  ///
  /// This was 1.0 m, which is far too late. At a walking pace of ~1.4 m/s a
  /// one-metre warning arrives 0.7 seconds before impact — less than the time
  /// it takes to hear the word, let alone stop. Worse, the user could watch a
  /// box appear on screen and get no buzz at all, because a detection at
  /// 1.2 m was filtered out silently.
  ///
  /// 3 m gives roughly two seconds to react, which is about the minimum
  /// useful. The cost is more chatter, which the per-label cooldown absorbs.
  /// Maximum warning range. Anything beyond this is ignored; anything inside it
  /// is announced with the distance actually measured, not with 3 m.
  ///
  /// This is a ceiling, not the distance that gets spoken. An obstacle at 2.6 m
  /// is announced as 2.6 m, and again as it closes.
  static const double _maxRangeM = 3.0;

  /// How much the distance must change before the same obstacle is re-announced.
  ///
  /// The estimate wanders a few centimetres frame to frame, so re-announcing on
  /// any change at all would talk continuously about a stationary object. Half a
  /// metre is well outside that noise and is roughly one announcement per third
  /// of the warning range — close enough to feel live, far enough apart to be
  /// separate sentences.
  static const double _updateDeltaM = 0.5;

  /// How much closer a LEFT or RIGHT obstacle must be to outrank a CENTER one.
  ///
  /// Reads as: "a side obstacle wins only if it is at least this much nearer".
  /// A judgement, not a measurement — like every constant in this file, it
  /// wants a walk with a tape measure before it is called tuned.
  static const double _sidePenaltyM = 0.75;

  /// Re-announce a stationary obstacle after this long, even if the distance has
  /// not moved. Someone standing still needs to be able to hear that the
  /// obstacle is still there.
  ///
  /// 5. Settled by use rather than by argument: 4 -> 8 to cut repetition, then
  /// back down because eight seconds of silence beside an obstacle that has not
  /// moved reads as the app having stopped — and silence is the one thing it
  /// must never imply.
  ///
  /// At walking pace it almost never fires; the half-metre rule gets there
  /// first. This really governs the standing-still case.
  static const int _repeatAfterSec = 4;

  /// How many times each announcement is spoken.
  ///
  /// One, now that the distance updates as the user approaches: the obstacle is
  /// naturally repeated every half metre, which is what saying it twice was for.
  /// Two would also not fit — 3 m at walking pace is about 2.1 seconds, and two
  /// announcements plus the gap run past 4 seconds, so the second would still be
  /// speaking after the user reached the obstacle.
  static const int _alertRepeats = 1;

  /// Pause between repeats, when there is more than one.
  static const int _alertGapMs = 700;

  /// Records detections to a CSV during a field walk. Idle unless switched on.
  final DetectionLogService _log = DetectionLogService();

  /// Per label, the distance last spoken aloud. Compared against the current
  /// reading to decide whether the user has moved enough to be told again.
  final Map<String, double> _saidM = {};

  /// An obstacle must be seen twice within a moment before it is announced,
  /// so a one-frame misreading never reaches the speaker.
  final DetectionConfirmer _confirmer = DetectionConfirmer();

  /// Per label, when it was last spoken.
  final Map<String, DateTime> _saidAt = {};

  /// When the last obstacle alert finished — sentence or buzz, whichever it
  /// was.
  ///
  /// Global rather than per label. The per-label [_saidAt] lets a second
  /// obstacle talk straight through the first one's quiet period, which is not
  /// a cooldown the user can hear.
  ///
  /// Stamped when the alert ENDS, not when it starts. Measured from the
  /// start, the cooldown minus the length of the announcement left about a
  /// tenth of a second of actual silence.
  DateTime? _lastAlertAt;

  /// Per label, when it was last seen at all. An obstacle that leaves the frame
  /// is forgotten, so returning to it is announced fresh rather than treated as
  /// a continuation of the approach before.
  final Map<String, DateTime> _lastSeenAt = {};
  static const _forgetSec = 5;

  // Last obstacle announced — used by "repeat" so a user who missed the
  // word can hear it again without waiting for the next detection cycle.
  TFLiteDetection? _lastAlert;
  double? _lastMetres;

  // A per-label cooldown lived here: one announcement every 4 s while an
  // obstacle stayed in range. The alert is now tied to the approach instead —
  // once per crossing of 2 m, however long the obstacle lingers — so a timer on
  // top of it would only suppress genuine new approaches.

  // Dark frame detection
  DateTime? _darkSince;

  /// How many times the current blockage has been announced, and when the last
  /// one was. Reset the moment light returns.
  int _darkWarnCount = 0;
  DateTime? _lastDarkWarn;
  /// Lens is covered — near total blackness.
  static const _darkThreshold  = 10;   // avg brightness 0-255

  /// Below this the frame has too little detail for the model to be believed.
  ///
  /// Measured on this device rather than guessed. 264 frames gave:
  ///
  ///   lens covered, face down    3
  ///   night scene, detecting    34-35   <- motorcycle found correctly here
  ///   lit scene                179
  ///
  /// An earlier value of 50 was set from reasoning alone and was badly wrong:
  /// 46% of real frames fell below it, including working night detections, so
  /// it would have blinded the app after dark — worse than the phantom walls
  /// it was meant to stop. The real gap between "covered" and "usable" sits
  /// far lower than it seems.
  static const _tooDarkToDetect = 18;

  /// Seconds of darkness before speaking. Was 10, which is a long time to walk
  /// believing the app is watching. Short enough now to be useful, long enough
  /// that passing a dark doorway does not trigger it.
  static const _darkWarnSec    = 4;

  /// When the last frame finished processing, and whether the user has been
  /// told that frames stopped arriving.
  DateTime _lastFrameAt = DateTime.now();
  bool _stallWarned = false;
  Timer? _watchdog;

  /// Frames arrive every ~300 ms. Five seconds of nothing means the camera has
  /// stopped feeding us and detection is dead.
  static const _stallSec = 5;

  @override
  void initState() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Announces when frames stop arriving.
  ///
  /// The app can go blind for reasons no amount of lifecycle handling covers:
  /// the camera being claimed by another app, a hardware error, thermal
  /// shutdown. In every case the screen keeps showing "Detection ON" and the
  /// user hears nothing — and silence is indistinguishable from a clear path.
  /// This makes the failure audible.
  void _startWatchdog() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Rebuilds the camera when the app comes back to the foreground.
  ///
  /// Android revokes camera access from background apps, so turning the screen
  /// off tears down the stream. Without this the app returns looking healthy —
  /// the badge still reads "Detection ON" — while no frames arrive at all.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  @override
  void didUpdateWidget(CameraScreen old) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }


  Future<void> _initCam() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Shows and speaks why there is no picture, instead of leaving the screen on
  /// a spinner forever. A sighted tester needs the reason on screen; a blind
  /// user needs to hear it.
  Future<void> _reportNoCamera(String message) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Called for every camera frame, ~30x a second. Frames arriving while a
  /// detection is in flight are dropped rather than queued — the user needs
  /// the newest view of the path, not a backlog of stale ones.
  void _onFrame(CameraImage image) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _runFrame(YuvFrame frame) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Everything that happens once a frame has been through the detector.
  ///
  /// Shared by both capture paths on purpose. The streaming path and the
  /// takePicture path differ only in how the pixels arrive; the range rules,
  /// the per-obstacle cooldown, the darkness gate and the announcements must
  /// not drift apart between them, which is exactly what happens when the
  /// second path is left as a simplified copy of the first.
  Future<void> _handleResults(
      List<TFLiteDetection> results, double brightness) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _start() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Tears the camera down and opens it again.
  ///
  /// Used by the retry button and by the picker. A USB camera that was
  /// unplugged and plugged back in gets a new handle, so the old controller has
  /// to be disposed rather than reused — reusing it fails silently and leaves
  /// the preview frozen on the last frame it managed, which reads as a working
  /// camera showing a static scene.
  Future<void> _retryCamera({CameraDescription? use}) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Lets the user pick a camera by hand.
  ///
  /// Windows can report several webcams — a laptop lid camera, a USB module,
  /// and sometimes a virtual one from a meeting app — and the names are not
  /// always obvious enough for the automatic choice to be right every time.
  Future<void> _pickCamera() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Starts or stops the detection recording, speaking the result so it can be
  /// confirmed without looking.
  Future<void> _toggleLog() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Long press — spoken status, so a user can check state without sight.
  Future<void> _speakStatus() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// The barangay name as it appears in a clip filename.
  ///
  /// Must match the names the recordings were saved under:
  /// "Capiñahan" -> capinahan, "Padre Inocentes Garcia (Pob.)" ->
  /// padre_inocentes_garcia_pob. Non-ASCII never reaches a filename — that is
  /// the class of lookup failure that kept every distance clip silent for
  /// weeks.
  static String? _brgySlug(String? name) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Which recorded place word describes [name], or null when none does.
  ///
  /// Only four words were recorded, so most OSM landmarks have no match and
  /// the sentence falls back to speech. Matching on the name rather than the
  /// category because the camera path builds NearbyPlace without one.
  /// Both languages, because the words that arrive here come from two very
  /// different sources: OpenStreetMap names them in English, and the user
  /// names their own saved places in Tagalog or Bisaya. Matching only English
  /// meant a landmark the user added themselves — "Tindahan ni Nena" — never
  /// found a word and was dropped from the announcement.
  static String? _placeWord(String name) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// The same sentence as PRE-JOINED phrases: at most two files instead of
  /// seven.
  ///
  /// Every join costs a completion-event round-trip through the platform's
  /// audio stack, and six of them stacked up into an audible stutter. These
  /// phrases are concatenated offline, so only one join is left.
  ///
  /// Falls back to [_locationClipsParts] when a combination was never
  /// rendered, so a missing phrase costs smoothness rather than the voice.
  static List<String>? _locationClipsJoined(
      BarangayResult bgy, NearbyPlace? nearest) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// The location sentence as a list of recorded clips, or null when it cannot
  /// be built entirely from recordings.
  ///
  /// All or nothing on purpose. Half the sentence in the user's voice and half
  /// in the synthetic one is worse than all of it synthesised, because the
  /// join lands in the middle of a place name.
  static List<String>? _locationClipsParts(
      BarangayResult bgy, NearbyPlace? nearest) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Tap — say where the user is. With a screen reader running this is the
  /// standard double-tap-to-activate gesture.
  ///
  /// Detection keeps running underneath; this only borrows the voice. The
  /// last obstacle is still available on long press via [_speakStatus].
  Future<void> _speakLocation() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Capture path for platforms with no frame stream.
  ///
  /// Windows is the reason this is not a fallback any more. `camera_windows`
  /// implements preview, takePicture and recording, but not
  /// [CameraController.startImageStream], so a desktop build has no way to
  /// receive raw frames. Each round trip here writes a JPEG to disk and reads
  /// it back, which is why this runs at one or two frames a second where the
  /// streaming path manages three or more.
  ///
  /// Everything after the capture is shared with the streaming path, so the
  /// range rules, the per-obstacle cooldown, the distance and the direction
  /// behave identically on both.
  Future<void> _run() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Tells the user the camera cannot see, instead of letting the model invent
  /// an obstacle from an empty frame.
  ///
  /// Triggers at [_tooDarkToDetect], not [_darkThreshold]: whenever detection
  /// is being suppressed the user must hear why, otherwise the app goes quiet
  /// and silence reads as "the path is clear".
  /// Spoken twice, 4 s apart, then it stops.
  ///
  /// Once is easy to miss — the phone may be in a pocket, the user may be near
  /// traffic, or another announcement may have just finished. Twice is hard to
  /// miss. Stopping after two matters just as much: an alert that repeats
  /// forever becomes background noise, and the user needs to be able to tell
  /// the difference between "the camera is covered" and "the path is clear",
  /// both of which sound like silence.
  static const _darkWarnRepeats = 2;

  Future<void> _checkDark(double avg) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Returns the obstacle due to be announced on this frame, or null.
  ///
  /// Every obstacle within [_maxRangeM] is eligible, and what gets spoken is the
  /// distance measured on this frame. 3 m is the ceiling on the range, never the
  /// number announced: an obstacle at 2.6 m is announced at 2.6 m.
  ///
  /// An obstacle is announced when it is newly in range, when it has moved
  /// [_updateDeltaM] closer or further since it was last spoken, or when
  /// [_repeatAfterSec] has passed. Announcing on every frame would talk three
  /// times a second; announcing only once would leave the distance stale as the
  /// user keeps walking.
  ///
  /// Nearest wins when several are due — that is the one about to be walked
  /// into.
  ({RangedDetection detection, bool speak})? _dueForAlert(
      List<RangedDetection> all) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Distance, with a penalty for sitting off the walking path.
  ///
  /// Lower wins. A centre obstacle scores its true distance; a left or right
  /// one scores [_sidePenaltyM] worse, so it only wins by being meaningfully
  /// closer.
  ///
  /// Not "centre only": the frame is split into thirds, and in portrait that
  /// is a narrow angle, so something reported as LEFT is still near the path
  /// rather than off in a field. Ignoring the sides outright would mean
  /// walking into a chair at 0.4 m because a post 2.9 m ahead outranked it.
  double _priority(RangedDetection r) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Warns about [r]. With [speak] false this is a buzz only — the obstacle has
  /// already been named and is simply nearer than when it was.
  Future<void> _alert(RangedDetection r, {required bool speak}) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  @override
  void dispose() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  // ── Whole camera area is the tap target ─────────────────────────────────────
  // Detection runs on its own from launch. A tap says where the user is;
  // the last obstacle is on long press, together with the detection status.
  Widget _tapArea() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _header() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _camView() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _chips() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}

// ── Bounding box painter ──────────────────────────────────────────────────────
class _Painter extends CustomPainter {
  final List<TFLiteDetection> detections;

  /// True when these detections came from the COCO fallback. Drawn amber and
  /// labelled, so it is clear which model is speaking — these classes were
  /// never trained on this project's own images.
  final bool fromFallback;

  final String? nearLabel;

  /// Vertical space at the top of the frame already occupied by the obstacle
  /// chips. Box labels are kept below it: an obstacle filling the view has no
  /// room above its box, so its label drops inside the top edge — which is
  /// precisely where the chips sit, and the two were drawing over each other.
  final double topInset;

  const _Painter({
    required this.detections,
    this.fromFallback = false,
    this.nearLabel,
    this.topInset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  void _drawBox(
    Canvas canvas,
    Size size,
    TFLiteDetection d, {
    required Color color,
    required bool isNear,
  }) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  @override
  bool shouldRepaint(_Painter old) => throw UnimplementedError('Implementation omitted in this showcase.');
}
