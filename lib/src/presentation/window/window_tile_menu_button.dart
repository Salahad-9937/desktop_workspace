import 'package:flutter/material.dart';

import '../../model/geometry_types.dart';

/// Кнопка вызова всплывающего меню предустановленных зон тайлинга.
class WindowTileMenuButton extends StatelessWidget {
  /// Обратный вызов выбора зоны тайлинга.
  final void Function(SnapZone zone) onTileSelect;

  /// Цвет пиктограммы меню.
  final Color iconColor;

  /// Создает экземпляр [WindowTileMenuButton].
  const WindowTileMenuButton({
    super.key,
    required this.onTileSelect,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SnapZone>(
      tooltip: 'Меню тайлинга',
      icon: Icon(Icons.grid_view_rounded, size: 14.0, color: iconColor),
      padding: EdgeInsets.zero,
      onSelected: onTileSelect,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SnapZone>>[
        const PopupMenuItem<SnapZone>(
          value: SnapZone.maximize,
          child: Row(
            children: <Widget>[
              Icon(Icons.crop_square_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('На весь экран', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
        const PopupMenuItem<SnapZone>(
          value: SnapZone.leftHalf,
          child: Row(
            children: <Widget>[
              Icon(Icons.align_horizontal_left_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('Левая половина', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
        const PopupMenuItem<SnapZone>(
          value: SnapZone.rightHalf,
          child: Row(
            children: <Widget>[
              Icon(Icons.align_horizontal_right_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('Правая половина', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
        const PopupMenuItem<SnapZone>(
          value: SnapZone.none,
          child: Row(
            children: <Widget>[
              Icon(Icons.layers_clear_rounded, size: 16.0),
              SizedBox(width: 8.0),
              Text('Снять тайлинг', style: TextStyle(fontSize: 12.0)),
            ],
          ),
        ),
      ],
    );
  }
}