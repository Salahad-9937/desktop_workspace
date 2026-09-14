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

/// Предопределенные определения панелей рабочего пространства.
final List<PanelDefinition> _sampleDefinitions = <PanelDefinition>[
  const PanelDefinition(
    id: 'view_dashboard',
    title: 'Дашборд аналитики',
    icon: Icons.dashboard_customize_rounded,
    accentColor: Color(0xFF00E5FF),
  ),
  const PanelDefinition(
    id: 'view_layers',
    title: 'Менеджер слоев',
    icon: Icons.layers_rounded,
    accentColor: Color(0xFF00E676),
  ),
  const PanelDefinition(
    id: 'view_settings',
    title: 'Конфигурация системы',
    icon: Icons.tune_rounded,
    accentColor: Color(0xFFFFAB00),
  ),
];

/// Шаблоны вкладок для проверки функционала оконного менеджера.
final List<WorkspaceTab> _sampleTemplates = _sampleDefinitions
    .map((PanelDefinition def) => def.toTab())
    .toList(growable: false);

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
          final Color accent = tab.accentColor ?? DesktopTheme.accentColor;

          return Center(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    tab.icon ?? Icons.web_asset_rounded,
                    size: 44.0,
                    color: accent,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Окно: ${win.id} | Вкладка: ${tab.id}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: DesktopTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}