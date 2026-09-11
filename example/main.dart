import 'package:desktop_workspace/desktop_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Точка входа в демонстрационное приложение.
void main() {
  runApp(
    const ProviderScope(
      child: DesktopWorkspaceExampleApp(),
    ),
  );
}

/// Шаблоны вкладок для проверки функционала оконного менеджера.
const List<WorkspaceTab> _sampleTemplates = <WorkspaceTab>[
  WorkspaceTab(
    id: 'view_1',
    title: 'Панель 1',
    icon: Icons.dashboard_customize_rounded,
    accentColor: Color(0xFF00E5FF),
  ),
  WorkspaceTab(
    id: 'view_2',
    title: 'Панель 2',
    icon: Icons.layers_rounded,
    accentColor: Color(0xFF00E676),
  ),
  WorkspaceTab(
    id: 'view_3',
    title: 'Панель 3',
    icon: Icons.tune_rounded,
    accentColor: Color(0xFFFFAB00),
  ),
];

/// Минимальное демонстрационное приложение рабочего пространства.
class DesktopWorkspaceExampleApp extends ConsumerStatefulWidget {
  /// Создает экземпляр [DesktopWorkspaceExampleApp].
  const DesktopWorkspaceExampleApp({super.key});

  @override
  ConsumerState<DesktopWorkspaceExampleApp> createState() =>
      _DesktopWorkspaceExampleAppState();
}

class _DesktopWorkspaceExampleAppState
    extends ConsumerState<DesktopWorkspaceExampleApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceControllerProvider.notifier).applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[_sampleTemplates[0]],
          <WorkspaceTab>[_sampleTemplates[1], _sampleTemplates[2]],
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desktop Workspace Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DesktopTheme.spaceBackground,
        colorScheme: const ColorScheme.dark(
          surface: DesktopTheme.panelBackground,
          primary: DesktopTheme.accentColor,
          secondary: DesktopTheme.secondaryAccent,
        ),
      ),
      home: DesktopCanvas(
        tabTemplates: _sampleTemplates,
        contentBuilder: (
          BuildContext context,
          WindowState win,
          WorkspaceTab tab,
        ) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  tab.icon ?? Icons.web_asset_rounded,
                  size: 40.0,
                  color: tab.accentColor ?? DesktopTheme.accentColor,
                ),
                const SizedBox(height: 12.0),
                Text(
                  tab.title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Окно: ${win.id} | Вкладка: ${tab.id}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: DesktopTheme.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
