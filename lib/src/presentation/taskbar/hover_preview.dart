import 'package:flutter/material.dart';
import '../../state/models/window_state.dart';
import '../../state/models/workspace_tab.dart';
import '../../theme/workspace_theme.dart';

/// Всплывающая карточка предварительного просмотра содержимого окна при наведении на панель задач.
class HoverPreview extends StatelessWidget {
  /// Состояние инспектируемого окна.
  final WindowState win;

  /// Активная вкладка окна.
  final WorkspaceTab tab;

  /// Создает экземпляр [HoverPreview].
  const HoverPreview({
    super.key,
    required this.win,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = tab.accentColor ?? DesktopTheme.accentColor;
    final IconData icon = tab.icon ?? Icons.web_asset_rounded;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1626),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: accent.withValues(alpha: 0.6),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black54,
              blurRadius: 14.0,
              offset: Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 72.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: const Color(0xFF1E2836)),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 26.0,
                color: accent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              tab.title,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            if (win.tabs.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  '+ ещё ${win.tabs.length - 1} вкладок в окне',
                  style: const TextStyle(
                    fontSize: 9.0,
                    color: Color(0xFF78909C),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Псевдоним обратной совместимости для [HoverPreview].
typedef HoverPreviewCard = HoverPreview;