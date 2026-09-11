import 'package:flutter/material.dart';

/// Всплывающая карточка детальной информации при клике на элемент системного трея.
class TrayPopupCard extends StatelessWidget {
  /// Заголовок карточки.
  final String title;

  /// Акцентный цвет модальности метрики.
  final Color color;

  /// Иконка для отображения в графической плашке.
  final IconData icon;

  /// Текстовое описание показателя или статуса.
  final String detail;

  /// Колбэк закрытия карточки.
  final VoidCallback onClose;

  /// Создает экземпляр [TrayPopupCard].
  const TrayPopupCard({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.detail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260.0,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1626),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: color.withValues(alpha: 0.6),
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16.0,
              offset: Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14.0,
                    color: Color(0xFF78909C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Container(
              height: 56.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                borderRadius: BorderRadius.circular(6.0),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: color.withValues(alpha: 0.7),
                size: 24.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF90A4AE),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
