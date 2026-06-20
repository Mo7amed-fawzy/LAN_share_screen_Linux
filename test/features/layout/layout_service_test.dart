import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/features/layout/domain/layout_service.dart';

void main() {
  group('LayoutService', () {
    late LayoutService service;

    setUp(() {
      service = LayoutService();
    });

    test('getGridColumns returns 1 for single participant', () {
      expect(service.getGridColumns(1), equals(1));
    });

    test('getGridColumns returns 2 for 2-4 participants', () {
      expect(service.getGridColumns(2), equals(2));
      expect(service.getGridColumns(3), equals(2));
      expect(service.getGridColumns(4), equals(2));
    });

    test('getGridColumns returns 3 for 5+ participants', () {
      expect(service.getGridColumns(5), equals(3));
      expect(service.getGridColumns(10), equals(3));
    });

    test('getThumbnailWidth caps at 160', () {
      final width = service.getThumbnailWidth(2000, 1);
      expect(width, equals(160));
    });

    test('getThumbnailWidth shrinks for many participants', () {
      final width = service.getThumbnailWidth(500, 10);
      expect(width, lessThan(160));
    });
  });
}
