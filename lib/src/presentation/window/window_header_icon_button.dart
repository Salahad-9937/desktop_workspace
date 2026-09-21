import 'package:flutter/material.dart';

/// Иконочная кнопка фиксированного размера для полосы заголовка окна.
class WindowHeaderIconButton extends StatefulWidget {
  /// Отображаемая пиктограмма.
  final IconData icon;

  /// Текст всплывающей подсказки.
  final String tooltip;

  /// Базовый цвет пиктограммы.
  final Color iconColor;

  /// Акцентный цвет при наведении курсора.
  final Color? hoverColor;

  /// Обратный вызов нажатия кнопки.
  final VoidCallback onPressed;

  /// Создает экземпляр [WindowHeaderIconButton].
  const WindowHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.iconColor,
    this.hoverColor,
    required this.onPressed,
  });

  @override
  State<WindowHeaderIconButton> createState() => _WindowHeaderIconButtonState();
}

class _WindowHeaderIconButtonState extends State<WindowHeaderIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          child: SizedBox(
            width: 32.0,
            height: 32.0,
            child: Icon(
              widget.icon,
              size: 14.0,
              color: _isHovered && widget.hoverColor != null
                  ? widget.hoverColor
                  : widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}