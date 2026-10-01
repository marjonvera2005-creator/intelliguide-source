import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import 'camera_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  final String language;
  const MainShell({super.key, required this.language});

  @override
  State<MainShell> createState() => throw UnimplementedError('Implementation omitted in this showcase.');
}

class _MainShellState extends State<MainShell> {
  int _index = 1;
  late String _lang;
  late final TtsService _tts;

  static const _names = ['Map', 'Camera', 'Settings'];

  @override
  void initState() {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  void _changeLang(String l) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }

  // Speak the destination — without sight there is no other way to know
  // which tab you landed on.
  void _goTo(int i) {
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

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}

class _Item extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Item(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Implementation omitted in this showcase.');
  }
}
