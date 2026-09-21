import 'package:desktop_workspace/src/engine/snap_zone_detector.dart';
import 'package:desktop_workspace/src/model/geometry_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SnapZoneDetector Tests', () {
    const WorkspaceRect area = WorkspaceRect(
      x: 0.0,
      y: 0.0,
      width: 1000.0,
      height: 800.0,
    );

    test('Определение зоны Maximize у верхнего края', () {
      final SnapZone zone = SnapZoneDetector.detectZone(
        pointerX: 500.0,
        pointerY: 15.0,
        availableArea: area,
        edgeThreshold: 48.0,
      );
      expect(zone, SnapZone.maximize);
    });

    test('Определение зоны LeftHalf у левого ребра по центру', () {
      final SnapZone zone = SnapZoneDetector.detectZone(
        pointerX: 20.0,
        pointerY: 400.0,
        availableArea: area,
        edgeThreshold: 48.0,
      );
      expect(zone, SnapZone.leftHalf);
    });

    test('Определение зоны TopRight в верхнем правом секторе', () {
      final SnapZone zone = SnapZoneDetector.detectZone(
        pointerX: 980.0,
        pointerY: 100.0,
        availableArea: area,
        edgeThreshold: 48.0,
      );
      expect(zone, SnapZone.topRight);
    });

    test('Расчет previewRect для половины и четверти экрана', () {
      final WorkspaceRect? leftPreview = SnapZoneDetector.calculatePreviewRect(
        zone: SnapZone.leftHalf,
        availableArea: area,
      );
      expect(leftPreview, isNotNull);
      expect(leftPreview!.width, 500.0);
      expect(leftPreview.height, 800.0);
      expect(leftPreview.x, 0.0);

      final WorkspaceRect? brPreview = SnapZoneDetector.calculatePreviewRect(
        zone: SnapZone.bottomRight,
        availableArea: area,
      );
      expect(brPreview, isNotNull);
      expect(brPreview!.width, 500.0);
      expect(brPreview.height, 400.0);
      expect(brPreview.x, 500.0);
      expect(brPreview.y, 400.0);
    });
  });
}