import 'package:desktop_workspace/src/theme/workspace_theme.dart';
import 'package:desktop_workspace/src/theme/workspace_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceTheme Tests', () {
    test('Контраст активного и неактивного фокуса в темах', () {
      const WorkspaceThemeData dark = WorkspaceThemeData.dark();
      const WorkspaceThemeData light = WorkspaceThemeData.light();

      expect(dark.borderActive != dark.borderInactive, isTrue);
      expect(light.borderActive != light.borderInactive, isTrue);
    });

    test('Интерполяция (lerp) и copyWith темы', () {
      const WorkspaceThemeData dark = WorkspaceThemeData.dark();
      final WorkspaceThemeData modified = dark.copyWith(windowRadius: 16.0);
      expect(modified.windowRadius, 16.0);

      final WorkspaceThemeData lerped = dark.lerp(modified, 0.5);
      expect(lerped.windowRadius, 12.0);
    });

    testWidgets('WorkspaceTheme.of читает тему из контекста',
        (WidgetTester tester) async {
      late WorkspaceThemeData extracted;

      await tester.pumpWidget(
        const WorkspaceTheme(
          data: WorkspaceThemeData.light(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: _ExtractThemeWidget.build,
              ),
            ),
          ),
        ),
      );

      extracted = _ExtractThemeWidget.lastExtracted!;
      expect(extracted.spaceBackground, const Color(0xFFF0F2F5));
    });
  });
}

class _ExtractThemeWidget {
  static WorkspaceThemeData? lastExtracted;

  static Widget build(BuildContext context) {
    lastExtracted = WorkspaceTheme.of(context);
    return const SizedBox();
  }
}