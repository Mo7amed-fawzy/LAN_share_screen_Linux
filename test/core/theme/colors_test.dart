import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/core/theme/colors.dart';

void main() {
  group('AppColors', () {
    test('has all required colors', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.surface, isNotNull);
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.success, isNotNull);
      expect(AppColors.error, isNotNull);
    });

    test('colors have expected values', () {
      expect(AppColors.success, const Color(0xFF22C55E));
      expect(AppColors.error, const Color(0xFFEF4444));
      expect(AppColors.primary, const Color(0xFF6366F1));
    });
  });
}
