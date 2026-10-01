import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'distance_estimator.dart';
import 'tflite_service.dart';

/// Records what the detector actually saw, so a wrong label can be diagnosed
/// from data instead of from memory.
///
/// The false `wall` and `bed` reports could not be pinned down by watching the
/// screen: the label changes faster than it can be read, and the tester is
/// walking. Any threshold chosen from a recollection of what the app said is a
/// guess. This writes every detection to a file the user can send back after a
/// walk, which turns "it detects wrong" into a list of labels and confidences.
///
/// Deliberately not Hive: this is a flat append-only trace, read once on a
/// laptop and deleted. A CSV is the right shape, and it costs no schema.
class DetectionLogService {
  /// Buffered lines waiting to be written. Writing per frame would put file IO
  /// on the detection path several times a second.
  final List<String> _pending = [];

  /// Flush once this many lines have collected.
  static const _flushEvery = 60;

  /// Stop growing the file after this many lines — roughly a 40 minute walk at
  /// a few detections a second. A log that fills the phone would be a worse
  /// bug than the one it is here to find.
  static const _maxLines = 20000;
  int _written = 0;

  File? _file;
  bool _enabled = false;
  bool get isEnabled => throw UnimplementedError('Implementation omitted in this showcase.');

  /// Where the log is being written, for the UI to show.
  String? get path => throw UnimplementedError('Implementation omitted in this showcase.');

  Future<bool> start() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> stop() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  /// Records one frame's detections. Called with the raw results, before any
  /// range filtering — the whole point is to see what was rejected and why.
  void record(
    List<TFLiteDetection> results, {
    required double brightness,
    required bool fromFallback,
  }) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _flush() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
