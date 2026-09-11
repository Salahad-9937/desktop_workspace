import 'package:desktop_workspace/desktop_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WindowState инициализируется с корректными параметрами', () {
    const WindowState window = WindowState(
      id: 'win_test',
      tabs: <WorkspaceTab>[
        WorkspaceTab(id: 'test_tab', title: 'Тестовая вкладка'),
      ],
      x: 100.0,
      y: 100.0,
      width: 500.0,
      height: 400.0,
    );

    expect(window.id, 'win_test');
    expect(window.activeTab?.id, 'test_tab');
    expect(window.activeTab?.title, 'Тестовая вкладка');
    expect(window.x, 100.0);
    expect(window.y, 100.0);
    expect(window.width, 500.0);
    expect(window.height, 400.0);
    expect(window.isMaximized, isFalse);
    expect(window.isMinimized, isFalse);
  });
}
