import 'package:flutter/material.dart';

import '../../model/view_definition.dart';
import '../../model/window_state.dart';
import '../../model/workspace_tab.dart';
import '../../theme/workspace_theme.dart';
import '../../theme/workspace_theme_data.dart';

/// Модальный диалог обнаружения и восстановления панелей из реестра.
class ViewCatalogPalette extends StatefulWidget {
  /// Список доступных прикладных представлений.
  final List<ViewDefinition> definitions;

  /// Текущий список открытых окон.
  final List<WindowState> currentWindows;

  /// Обратный вызов выбора представления.
  final void Function(ViewDefinition def, ViewInstanceStatus status)
      onSelectDefinition;

  /// Создает экземпляр [ViewCatalogPalette].
  const ViewCatalogPalette({
    super.key,
    required this.definitions,
    required this.currentWindows,
    required this.onSelectDefinition,
  });

  /// Открывает диалог палитры каталога представлений.
  static Future<void> show({
    required BuildContext context,
    required List<ViewDefinition> definitions,
    required List<WindowState> currentWindows,
    required void Function(ViewDefinition def, ViewInstanceStatus status)
        onSelectDefinition,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return ViewCatalogPalette(
          definitions: definitions,
          currentWindows: currentWindows,
          onSelectDefinition: onSelectDefinition,
        );
      },
    );
  }

  @override
  State<ViewCatalogPalette> createState() => _ViewCatalogPaletteState();
}

class _ViewCatalogPaletteState extends State<ViewCatalogPalette> {
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  ViewInstanceStatus _resolveStatus(ViewDefinition def) {
    bool hasActive = false;
    bool hasMinimized = false;
    bool hasInactive = false;

    for (final WindowState w in widget.currentWindows) {
      for (final WorkspaceTab t in w.tabs) {
        if (t.typeId == def.typeId) {
          if (w.isMinimized) {
            hasMinimized = true;
          } else if (w.tabs.indexOf(t) == w.activeTabIndex) {
            hasActive = true;
          } else {
            hasInactive = true;
          }
        }
      }
    }

    if (hasActive) {
      return ViewInstanceStatus.active;
    }
    if (hasInactive) {
      return ViewInstanceStatus.inactive;
    }
    if (hasMinimized) {
      return ViewInstanceStatus.minimized;
    }
    return ViewInstanceStatus.closed;
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);
    final List<ViewDefinition> filtered = widget.definitions
        .where(
          (ViewDefinition d) =>
              d.title.toLowerCase().contains(_filter.toLowerCase()),
        )
        .toList();

    return Dialog(
      backgroundColor: theme.windowBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.windowRadius),
        side: BorderSide(color: theme.borderActive, width: 1.0),
      ),
      child: Container(
        width: 440.0,
        height: 480.0,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.grid_view_rounded,
                  size: 20.0,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Панели и компоненты',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16.0),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _filterController,
              onChanged: (String val) => setState(() => _filter = val),
              decoration: InputDecoration(
                hintText: 'Поиск по панелям...',
                prefixIcon: const Icon(Icons.search_rounded, size: 16.0),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1.0),
                itemBuilder: (BuildContext context, int index) {
                  final ViewDefinition def = filtered[index];
                  final ViewInstanceStatus status = _resolveStatus(def);

                  return ListTile(
                    leading: Icon(
                      def.icon ?? Icons.dashboard_rounded,
                      color: def.accentColor ?? theme.accentColor,
                      size: 22.0,
                    ),
                    title: Text(
                      def.title,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    trailing: _StatusBadge(status: status),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelectDefinition(def, status);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ViewInstanceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final WorkspaceThemeData theme = WorkspaceTheme.of(context);

    final (String label, Color color) = switch (status) {
      ViewInstanceStatus.active => ('Активна', theme.accentColor),
      ViewInstanceStatus.inactive => ('На холсте', theme.textMuted),
      ViewInstanceStatus.minimized => ('Свернута', theme.warningColor),
      ViewInstanceStatus.closed => (
          'Открыть',
          theme.accentColor
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}