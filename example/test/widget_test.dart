import 'package:desktop_workspace_example/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Smoke-тест инициализации и монтирования DesktopWorkspaceExampleApp',
    (WidgetTester tester) async {
      initializePanels();

      await tester.pumpWidget(
        const ProviderScope(
          child: DesktopWorkspaceExampleApp(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(DesktopWorkspaceExampleApp), findsOneWidget);
    },
  );
}