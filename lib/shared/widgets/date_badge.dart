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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fgColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 5),
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
