import 'package:desktop_workspace/desktop_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Точка входа в демонстрационное приложение многооконного рабочего пространства.
void main() {
  initializePanels();
  runApp(
    const ProviderScope(
      child: DesktopWorkspaceExampleApp(),
    ),
  );
}

/// Выполняет декларативную регистрацию модулей в [PanelRegistry].
void initializePanels() {
  PanelRegistry.instance.clear();
  PanelRegistry.instance.registerAll(<PanelDefinition>[
    PanelDefinition(
      id: 'view_counter',
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
    PanelDefinition(
      id: 'view_analytics',
      title: 'Дашборд аналитики',
      icon: Icons.analytics_outlined,
      accentColor: const Color(0xFF00E676),
      keepAlive: true,
      builder: (BuildContext context, WindowState win, WorkspaceTab tab) {
        return const AnalyticsMockPanel();
      },
    ),
    PanelDefinition(
      id: 'view_settings',
      title: 'Параметры и тема',
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
  ]);
}

/// Панель с локальным изменяемым состоянием для валидации сохранения стейта при смене вкладок.
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Состояние сохраняется в памяти (keepAlive: true)',
            style: TextStyle(
              fontSize: 12.0,
              color: theme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14.0),
          Text(
            'Значение: $_counter',
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: () => setState(() => _counter++),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Прибавить'),
              ),
              const SizedBox(width: 8.0),
              OutlinedButton.icon(
                onPressed: () => setState(() => _counter = 0),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Сбросить'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Введенный текст сохраняется при переключении табов',
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
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Потоковая отрисовка окон без Rebuild Thrashing',
            style: TextStyle(
              fontSize: 12.0,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Панель управления параметрами окружения и стилизации.
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
            title: const Text('Дизайн-система ThemeExtension'),
            subtitle: const Text('Поддержка светлой, темной и корпоративной тем'),
          ),
          ListTile(
            leading: Icon(Icons.language_rounded, color: theme.accentColor),
            title: const Text('Локализация через WorkspaceLocalizations'),
            subtitle: const Text('Готовые контракты для русского и английского языков'),
          ),
          ListTile(
            leading: Icon(Icons.view_quilt_rounded, color: theme.secondaryAccent),
            title: const Text('Сетки, тайлинг и общий шов'),
            subtitle: const Text('Индивидуальные WindowConstraints на уровне панелей'),
          ),
        ],
      ),
    );
  }
}

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
  bool _isDark = true;
  bool _isRussian = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final List<WorkspaceTab> tabs = PanelRegistry.instance.toTabs();
      ref.read(workspaceControllerProvider.notifier).applyPresetSplit(
        windowsTabs: <List<WorkspaceTab>>[
          <WorkspaceTab>[tabs[0]],
          <WorkspaceTab>[tabs[1], tabs[2]],
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData workspaceTheme = _isDark
        ? const WorkspaceThemeData.dark()
        : const WorkspaceThemeData.light();

    final WorkspaceStrings strings = _isRussian
        ? const DefaultWorkspaceStrings()
        : const EnglishWorkspaceStrings();

    return MaterialApp(
      title: 'Desktop Workspace Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: workspaceTheme.spaceBackground,
        extensions: <ThemeExtension<dynamic>>[workspaceTheme],
      ),
      home: WorkspaceLocalizations(
        strings: strings,
        child: DesktopCanvas(
          tabTemplates: PanelRegistry.instance.toTabs(),
          taskbarTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 16.0,
                ),
                tooltip: 'Переключить тему',
                onPressed: () => setState(() => _isDark = !_isDark),
              ),
              IconButton(
                icon: const Icon(Icons.translate_rounded, size: 16.0),
                tooltip: 'Switch language / Сменить язык',
                onPressed: () => setState(() => _isRussian = !_isRussian),
              ),
              const SizedBox(width: 6.0),
              const SystemTray(),
            ],
          ),
        ),
      ),
    );
  }
}