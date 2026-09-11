import 'package:flutter/material.dart';
import '../../theme/desktop_theme.dart';
import 'tray_popup_card.dart';

/// Системный трей панели задач с системным временем и настраиваемыми индикаторами.
class DesktopSystemTray extends StatefulWidget {
  /// Список дополнительных пользовательских виджетов индикации.
  final List<Widget>? customIndicators;

  /// Создает экземпляр [DesktopSystemTray].
  const DesktopSystemTray({
    super.key,
    this.customIndicators,
  });

  @override
  State<DesktopSystemTray> createState() => _DesktopSystemTrayState();
}

class _DesktopSystemTrayState extends State<DesktopSystemTray> {
  final LayerLink _trayLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showClockPopup() {
    _removePopup();
    final DateTime now = DateTime.now();
    final String dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removePopup,
            ),
          ),
          CompositedTransformFollower(
            link: _trayLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0.0, -8.0),
            child: TrayPopupCard(
              title: 'Системное время',
              color: DesktopTheme.accentColor,
              icon: Icons.access_time_rounded,
              detail:
                  'Текущая дата: $dateStr\nМногооконное рабочее пространство активно.',
              onClose: _removePopup,
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removePopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return CompositedTransformTarget(
      link: _trayLink,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.customIndicators != null) ...widget.customIndicators!,
          InkWell(
            onTap: _showClockPopup,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: DesktopTheme.panelBackground,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: DesktopTheme.surfaceBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13.0,
                    color: DesktopTheme.accentColor,
                  ),
                  const SizedBox(width: 5.0),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
