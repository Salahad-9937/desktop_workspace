import 'package:flutter/material.dart';

/// Компактная кнопка быстрого закрытия чипа вкладки с эффектом наведения.
class TabCloseButton extends StatefulWidget {
  /// Обратный вызов закрытия вкладки.
  final VoidCallback onClose;

  /// Цвет пиктограммы в состоянии покоя.
  final Color normalColor;

  /// Цвет подсветки и пиктограммы при наведении.
  final Color hoverColor;

  /// Создает экземпляр [TabCloseButton].
  const TabCloseButton({
    super.key,
    required this.onClose,
    required this.normalColor,
    required this.hoverColor,
  });

  @override
  State<TabCloseButton> createState() => _TabCloseButtonState();
}

class _TabCloseButtonState extends State<TabCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        child: Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.hoverColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(3.0),
          ),
          child: Center(
            child: Icon(
              Icons.close_rounded,
              size: 11.0,
              color: _isHovered ? widget.hoverColor : widget.normalColor,
            ),
          ),
        ),
      ),
    );
  }
}