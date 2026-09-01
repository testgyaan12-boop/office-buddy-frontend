import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/goal_model.dart';

class GoalTab extends StatelessWidget {
  final GoalModel goal;

  const GoalTab({super.key, required this.goal});

  Color _urgencyColor(int days) {
    if (goal.isCompleted) return AppColors.success;
    if (days <= 0) return AppColors.error;
    if (days <= 10) return AppColors.warning;
    if (days <= 20) return Colors.orange;
    return AppColors.success;
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'career':
        return Icons.work;
      case 'package':
        return Icons.trending_up;
      case 'skill':
        return Icons.school;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(goal.remainingDays);
    return GestureDetector(
      onTap: () => context.push('/goals'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(_categoryIcon(goal.category), size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                goal.isCompleted
                    ? 'Completed'
                    : goal.isOverdue
                        ? 'Overdue'
                        : '${goal.remainingDays} days left',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddGoalTab extends StatelessWidget {
  const AddGoalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/goals'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.4), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary.withValues(alpha: 0.6), size: 28),
            const SizedBox(height: 4),
            Text(
              'Add Goal',
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
