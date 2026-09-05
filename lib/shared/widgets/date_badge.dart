import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DateBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final double fontSize;

  const DateBadge(
    this.label, {
    super.key,
    this.icon,
    this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = (color ?? AppColors.primary).withOpacity(0.1);
    final fgColor = color ?? AppColors.primary;
    final isSmall = fontSize <= 9;
    final hPad = isSmall ? 6.0 : 10.0;
    final vPad = isSmall ? 3.0 : 5.0;
    final iconSize = isSmall ? 10.0 : 14.0;
    final gap = isSmall ? 3.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
        border: Border.all(color: fgColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fgColor),
            SizedBox(width: gap),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
