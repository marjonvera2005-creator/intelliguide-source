import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import 'main_shell.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => throw UnimplementedError('Implementation omitted in this showcase.');
}

class _LanguageScreenState extends State<LanguageScreen> {
  late final TtsService _tts;

  static const _langs = [
    {'code': 'en',  'label': 'English',  'sub': 'Voice guidance in English'},
    {'code': 'tl',  'label': 'Tagalog',  'sub': 'Gabay sa wikang Tagalog'},
    {'code': 'ceb', 'label': 'Bisaya',   'sub': 'Giya sa Bisaya / Cebuano'},
  ];

  @override
  void initState() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  Future<void> _pick(String code) async {
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
}

class _LangButton extends StatelessWidget {
  final String code, label, sub;
  final VoidCallback onTap;
  const _LangButton(
      {required this.code,
      required this.label,
      required this.sub,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
