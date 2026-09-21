import 'dart:async';
import 'package:desktop_workspace/desktop_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DesktopWorkspaceExampleApp(),
    ),
  );
}

/// Список определений прикладных представлений для каталога.
final List<ViewDefinition> exampleViewDefinitions = <ViewDefinition>[
  ViewDefinition(
    typeId: 'view_counter',
    title: 'Интерактивный счетчик',
    icon: Icons.add_circle_outline_rounded,
    accentColor: const Color(0xFF00E5FF),
    keepAlive: true,
    constraints: const WindowConstraints(
      minWidth: 320.0,
      minHeight: 240.0,
    ),
    builder: (BuildContext context, WindowState win, WorkspaceTab tab) {
      return const CounterStatefulPanel();
    },
  ),
  ViewDefinition(
    typeId: 'view_analytics',
    title: 'Дашборд аналитики',
    icon: Icons.analytics_outlined,
    accentColor: const Color(0xFF00E676),
    keepAlive: true,
    builder: (BuildContext context, WindowState win, WorkspaceTab tab) {
      return const AnalyticsMockPanel();
    },
  ),
  ViewDefinition(
    typeId: 'view_settings',
    title: 'Параметры окружения',
    icon: Icons.settings_suggest_rounded,
    accentColor: const Color(0xFFFFAB00),
    keepAlive: true,
    constraints: const WindowConstraints(
      minWidth: 360.0,
      minHeight: 280.0,
    ),
    builder: (BuildContext context, WindowState win, WorkspaceTab tab) {
      return const SettingsControlPanel();
    },
  ),
];

/// Панель с локальным состоянием для проверки сохранения данных при смене вкладок.
class CounterStatefulPanel extends StatefulWidget {
  /// Создает экземпляр [CounterStatefulPanel].
  const CounterStatefulPanel({super.key});

  @override
  State<CounterStatefulPanel> createState() => _CounterStatefulPanelState();
}

class _CounterStatefulPanelState extends State<CounterStatefulPanel> {
  int _counter = 0;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Состояние удерживается в памяти (keepAlive: true)',
            style: TextStyle(fontSize: 12.0, color: theme.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14.0),
          Text(
            'Значение: $_counter',
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: <Widget>[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                onPressed: () => setState(() => _counter++),
                icon: const Icon(Icons.add_rounded, size: 16.0),
                label: const Text('Прибавить'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                onPressed: () => setState(() => _counter = 0),
                icon: const Icon(Icons.refresh_rounded, size: 16.0),
                label: const Text('Сбросить'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Введенный текст сохраняется при смене табов',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Панель визуализации аналитических данных.
class AnalyticsMockPanel extends StatelessWidget {
  /// Создает экземпляр [AnalyticsMockPanel].
  const AnalyticsMockPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.query_stats_rounded,
            size: 48.0,
            color: theme.accentColor,
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Мониторинг метрик активен',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Изоляция рендеринга без каскадных Rebuilds',
            style: TextStyle(fontSize: 12.0, color: theme.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Панель управления параметрами.
class SettingsControlPanel extends StatelessWidget {
  /// Создает экземпляр [SettingsControlPanel].
  const SettingsControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.palette_outlined, color: theme.warningColor),
            title: const Text('Дизайн-токены ThemeExtension'),
            subtitle: const Text('Полноценная поддержка светлой и темной тем'),
          ),
          ListTile(
            leading: Icon(Icons.view_quilt_rounded, color: theme.secondaryAccent),
            title: const Text('Сетки, тайлинг и общий шов'),
            subtitle: const Text('Синхронное масштабирование состыкованных окон'),
          ),
        ],
      ),
    );
  }
}

/// Демонстрационное приложение рабочего пространства.
class DesktopWorkspaceExampleApp extends ConsumerStatefulWidget {
  /// Создает экземпляр [DesktopWorkspaceExampleApp].
  const DesktopWorkspaceExampleApp({super.key});

  @override
  ConsumerState<DesktopWorkspaceExampleApp> createState() =>
      _DesktopWorkspaceExampleAppState();
}

class _DesktopWorkspaceExampleAppState
    extends ConsumerState<DesktopWorkspaceExampleApp> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workspaceControllerProvider.notifier).applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[exampleViewDefinitions[0].toTab()],
          <WorkspaceTab>[
            exampleViewDefinitions[1].toTab(),
            exampleViewDefinitions[2].toTab(),
          ],
        ],
      );
    });
  }

  void _openCatalog(BuildContext innerContext) {
    final WorkspaceState state = ref.read(workspaceControllerProvider);
    final WorkspaceController controller =
        ref.read(workspaceControllerProvider.notifier);

    unawaited(
      ViewCatalogPalette.show(
        context: innerContext,
        definitions: exampleViewDefinitions,
        currentWindows: state.windows,
        onSelectDefinition: (ViewDefinition def, ViewInstanceStatus status) {
          controller.openView(definition: def);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData workspaceTheme = _isDark
        ? const WorkspaceThemeData.dark()
        : const WorkspaceThemeData.light();

    return MaterialApp(
      title: 'Desktop Workspace Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: workspaceTheme.spaceBackground,
        extensions: <ThemeExtension<dynamic>>[workspaceTheme],
      ),
      home: Builder(
        builder: (BuildContext innerContext) {
          return WorkspaceTheme(
            data: workspaceTheme,
            child: WorkspaceCanvas(
              views: exampleViewDefinitions,
              dockLeading: IconButton(
                icon: const Icon(Icons.grid_view_rounded, size: 18.0),
                tooltip: 'Открыть каталог представлений',
                onPressed: () => _openCatalog(innerContext),
              ),
              dockTrailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      _isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 16.0,
                    ),
                    tooltip: 'Переключить тему',
                    onPressed: () => setState(() => _isDark = !_isDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 16.0),
                    tooltip: 'Сбросить в сплит 50/50',
                    onPressed: () {
                      ref
                          .read(workspaceControllerProvider.notifier)
                          .applyPresetSplit(
                        windowsTabs: <List<WorkspaceTab>>[
                          <WorkspaceTab>[exampleViewDefinitions[0].toTab()],
                          <WorkspaceTab>[
                            exampleViewDefinitions[1].toTab(),
                            exampleViewDefinitions[2].toTab(),
                          ],
                        ],
                      );
                    },
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