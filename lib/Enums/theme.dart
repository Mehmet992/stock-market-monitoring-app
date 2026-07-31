import 'package:flutter/material.dart';

enum Theme {
  system(
    code: 'system',
    displayName: 'System Default',
    icon: Icons.brightness_auto,
    mode: ThemeMode.system,
  ),
  light(
    code: 'light',
    displayName: 'Light Mode',
    icon: Icons.light_mode,
    mode: ThemeMode.light,
  ),
  dark(
    code: 'dark',
    displayName: 'Dark Mode',
    icon: Icons.dark_mode,
    mode: ThemeMode.dark,
  );

  final String code;
  final String displayName;
  final IconData icon;
  final ThemeMode mode;

  const Theme({
    required this.code,
    required this.displayName,
    required this.icon,
    required this.mode,
  });

  // Helper to safely convert Firestore string back into an AppTheme Enum
  static Theme fromCode(String? code, {Theme fallback = Theme.system}) {
    if (code == null) return fallback;
    return Theme.values.firstWhere(
          (t) => t.code.toLowerCase() == code.toLowerCase(),
      orElse: () => fallback,
    );
  }
}