import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/workspace_controller.dart';
import '../../models/window_state.dart';
import '../../models/workspace_state.dart';
import '../../models/workspace_tab.dart';
import '../../theme/desktop_theme.dart';
import 'system_tray.dart';
import 'taskbar_item.dart';

/// Закрепленная панель задач рабочего стола с кнопкой меню, списком окон, меню пресетов и треем.
class DesktopTaskbar extends ConsumerWidget {
  /// Кастомный виджет системного трея (если null — отображаются часы по умолчанию).
  final Widget? trailing;

  /// Кастомная кнопка запуска приложений (если null — отображается кнопка по умолчанию).
  final Widget? leading;

  /// Доступные шаблоны модулей для лаунчера создания окон.
  final List<WorkspaceTab>? tabTemplates;

  /// Создает экземпляр [DesktopTaskbar].
  const DesktopTaskbar({
    super.key,
    this.trailing,
    this.leading,
    this.tabTemplates,
  });

  Future<void> _showLauncherMenu(BuildContext context, WidgetRef ref) async {
    if (tabTemplates == null || tabTemplates!.isEmpty) {
      ref.read(workspaceControllerProvider.notifier).addWindow();
      return;
    }

    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final double screenHeight = overlay?.size.height ?? 800.0;

    final WorkspaceTab? chosen = await showMenu<WorkspaceTab>(
      context: context,
      position: RelativeRect.fromLTRB(
        10.0,
        screenHeight - 340.0,
        250.0,
        50.0,
      ),
      color: const Color(0xFF0F1626),
      items: tabTemplates!.map((WorkspaceTab template) {
        final Color accent = template.accentColor ?? DesktopTheme.accentColor;
        return PopupMenuItem<WorkspaceTab>(
          value: template,
          child: Row(
            children: <Widget>[
              if (template.icon != null) ...<Widget>[
                Icon(template.icon, size: 16.0, color: accent),
                const SizedBox(width: 10.0),
              ],
              Expanded(
                child: Text(
                  template.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (chosen != null) {
      ref.read(workspaceControllerProvider.notifier).addWindow(tab: chosen);
    }
  }

  Future<void> _exportLayout(BuildContext context, WidgetRef ref) async {
    final String json =
        ref.read(workspaceControllerProvider.notifier).exportLayoutJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Раскладка окон скопирована в буфер обмена (JSON)',
          ),
        ),
      );
    }
  }

  Future<void> _importLayout(BuildContext context, WidgetRef ref) async {
    final ClipboardData? data = await Clipboard.getData('text/plain');
    final String? text = data?.text;
    if (text == null) {
      return;
    }
    final bool success =
        ref.read(workspaceControllerProvider.notifier).importLayoutJson(text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Раскладка успешно восстановлена из буфера обмена'
                : 'Не удалось прочитать JSON-конфигурацию из буфера',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorkspaceState workspace = ref.watch(workspaceControllerProvider);
    final WorkspaceController notifier =
        ref.read(workspaceControllerProvider.notifier);

    return Container(
      color: const Color(0xFF0A0E18),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          leading ??
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      DesktopTheme.accentColor.withValues(alpha: 0.15),
                  foregroundColor: DesktopTheme.accentColor,
                  side: const BorderSide(color: DesktopTheme.accentColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.apps_rounded, size: 16.0),
                label: const Text(
                  'МЕНЮ',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => unawaited(_showLauncherMenu(context, ref)),
              ),
          const SizedBox(width: 8.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final WindowState win in workspace.windows)
                    TaskbarItem(win: win),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.dashboard_customize_rounded,
              size: 16.0,
              color: DesktopTheme.accentColor,
            ),
            tooltip: 'Пресеты компоновки и экспорт раскладки',
            color: const Color(0xFF101726),
            itemBuilder: (BuildContext ctx) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: '2x2',
                child: Text(
                  'Пресет: Сетка 2x2',
                  style: TextStyle(fontSize: 12.0),
                ),
              ),
              PopupMenuItem<String>(
                value: 'split',
                child: Text(
                  'Пресет: Разделенный экран',
                  style: TextStyle(fontSize: 12.0),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'export',
                child: Text(
                  'Сохранить раскладку (в буфер, JSON)',
                  style: TextStyle(fontSize: 12.0),
                ),
              ),
              PopupMenuItem<String>(
                value: 'import',
                child: Text(
                  'Восстановить раскладку (из буфера)',
                  style: TextStyle(fontSize: 12.0),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text(
                  'Закрыть все окна',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: DesktopTheme.errorColor,
                  ),
                ),
              ),
            ],
            onSelected: (String val) {
              switch (val) {
                case '2x2':
                  notifier.applyPresetLayout2x2();
                case 'split':
                  notifier.applyPresetSplit();
                case 'export':
                  unawaited(_exportLayout(context, ref));
                case 'import':
                  unawaited(_importLayout(context, ref));
                case 'clear':
                  notifier.clearAllWindows();
              }
            },
          ),
          const SizedBox(width: 8.0),
          const VerticalDivider(
            color: DesktopTheme.surfaceBorder,
            width: 1.0,
          ),
          const SizedBox(width: 8.0),
          trailing ?? const DesktopSystemTray(),
        ],
      ),
    );
  }
}
