import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String language;
  final ValueChanged<String> onLanguageChanged;
  const SettingsScreen(
      {super.key,
      required this.language,
      required this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => throw UnimplementedError('Implementation omitted in this showcase.');
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _sel;

  static const _langs = [
    {'code': 'en',  'label': 'English',
     'sub': 'Voice guidance in English',  'flag': '🇺🇸'},
    {'code': 'tl',  'label': 'Tagalog',
     'sub': 'Gabay sa wikang Tagalog',     'flag': '🇵🇭'},
    {'code': 'ceb', 'label': 'Bisaya',
     'sub': 'Giya sa Bisaya / Cebuano',   'flag': '🇵🇭'},
  ];

  @override
  void initState() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _pick(String code) async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _header() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _sectionLabel(String t) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _langTile(Map<String, String> l) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _historyTile() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _openHistory() async {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _infoCard() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Widget _feature(IconData icon, String text) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
