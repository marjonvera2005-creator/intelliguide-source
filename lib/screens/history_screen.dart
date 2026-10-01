import 'package:flutter/material.dart';

import '../services/haptic_service.dart';
import '../services/history_service.dart';

/// Shows the log of places the user has asked to be located, newest first.
///
/// Read-only apart from clearing. Nothing here feeds back into announcements —
/// this is a record, not a source of place names.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => throw UnimplementedError('Implementation omitted in this showcase.');
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _history = HistoryService();
  List<HistoryEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _load() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _export() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _confirmClear() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _empty() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _tile(HistoryEntry e) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  String _when(DateTime t) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
