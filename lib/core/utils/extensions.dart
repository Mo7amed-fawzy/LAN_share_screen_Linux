import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  bool get isSmallScreen => screenSize.width < 800;
}

extension StringExtensions on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';

  String get initials {
    final parts = split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return this[0].toUpperCase();
  }
}
