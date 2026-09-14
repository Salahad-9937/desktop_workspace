import 'package:flutter/material.dart';
import '../../state/models/geometry_types.dart';

/// Виджет визуализации краевых зон магнитного прилипания к экрану.
class SnapDockGuides extends StatelessWidget {
  /// Текущая активная зона прилипания при перетаскивании.
  final SnapZone pendingSnapZone;

  /// Создает экземпляр [SnapDockGuides].
  const SnapDockGuides({
    super.key,
    required this.pendingSnapZone,
  });

  Widget _buildDockZone({
    required SnapZone zone,
    required Alignment alignment,
    required double? width,
    required double? height,
    required IconData icon,
    required String label,
    required bool isVertical,
  }) {
    final bool isHighlighted = pendingSnapZone == zone;

    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
              : const Color(0xFF0B111D).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFF00E5FF)
                : const Color(0xFF162132).withValues(alpha: 0.5),
            width: isHighlighted ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: isHighlighted ? 1.0 : 0.45,
            child: isVertical
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        icon,
                        size: 13.0,
                        color: isHighlighted
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF78909C),
                      ),
                      const SizedBox(height: 6.0),
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 8.5,
                            letterSpacing: 0.8,
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isHighlighted
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF78909C),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        icon,
                        size: 14.0,
                        color: isHighlighted
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF78909C),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9.0,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isHighlighted
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF78909C),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double guideBreadth = 24.0;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double h = constraints.maxHeight;
          final double quarterH = h * 0.35;
          final double halfH = h * 0.30;

          return Stack(
            children: <Widget>[
              _buildDockZone(
                zone: SnapZone.maximize,
                alignment: Alignment.topCenter,
                width: 240.0,
                height: 28.0,
                icon: Icons.fullscreen_rounded,
                label: 'ВЕСЬ ЭКРАН',
                isVertical: false,
              ),
              _buildDockZone(
                zone: SnapZone.topLeft,
                alignment: Alignment.topLeft,
                width: guideBreadth,
                height: quarterH,
                icon: Icons.north_west_rounded,
                label: 'ВЕРХНЯЯ 1/4',
                isVertical: true,
              ),
              Positioned(
                left: 0.0,
                top: quarterH,
                width: guideBreadth,
                height: halfH,
                child: _buildDockZone(
                  zone: SnapZone.left,
                  alignment: Alignment.centerLeft,
                  width: guideBreadth,
                  height: halfH,
                  icon: Icons.dock_rounded,
                  label: 'ЛЕВАЯ ПОЛОВИНА',
                  isVertical: true,
                ),
              ),
              _buildDockZone(
                zone: SnapZone.bottomLeft,
                alignment: Alignment.bottomLeft,
                width: guideBreadth,
                height: quarterH,
                icon: Icons.south_west_rounded,
                label: 'НИЖНЯЯ 1/4',
                isVertical: true,
              ),
              _buildDockZone(
                zone: SnapZone.topRight,
                alignment: Alignment.topRight,
                width: guideBreadth,
                height: quarterH,
                icon: Icons.north_east_rounded,
                label: 'ВЕРХНЯЯ 1/4',
                isVertical: true,
              ),
              Positioned(
                right: 0.0,
                top: quarterH,
                width: guideBreadth,
                height: halfH,
                child: _buildDockZone(
                  zone: SnapZone.right,
                  alignment: Alignment.centerRight,
                  width: guideBreadth,
                  height: halfH,
                  icon: Icons.dock_rounded,
                  label: 'ПРАВАЯ ПОЛОВИНА',
                  isVertical: true,
                ),
              ),
              _buildDockZone(
                zone: SnapZone.bottomRight,
                alignment: Alignment.bottomRight,
                width: guideBreadth,
                height: quarterH,
                icon: Icons.south_east_rounded,
                label: 'НИЖНЯЯ 1/4',
                isVertical: true,
              ),
            ],
          );
        },
      ),
    );
  }
}