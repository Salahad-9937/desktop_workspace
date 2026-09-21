import 'package:flutter/material.dart';

/// Визуальный маркер позиции вставки вкладки при операции перетаскивания.
class TabDropIndicator extends StatelessWidget {
  /// Размещается ли маркер по левому краю чипа.
  final bool isLeft;

  /// Цвет индикатора позиции вставки.
  final Color color;

  /// Создает экземпляр [TabDropIndicator].
  const TabDropIndicator({
    super.key,
    required this.isLeft,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isLeft ? -1.5 : null,
      right: isLeft ? null : -1.5,
      top: 2.0,
      bottom: 2.0,
      width: 3.0,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.8),
              blurRadius: 4.0,
            ),
          ],
        ),
      ),
    );
  }
}