import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../core/constants/app_colors.dart';
import 'goal_provider.dart';
import 'models/goal_model.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(goalProvider.notifier).loadAllGoals());
  }

  void _showAddGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _GoalFormSheet(
        onSave: (title, description, targetDate, category) {
          ref.read(goalProvider.notifier).createGoal(
                title: title,
                description: description,
                targetDate: targetDate,
                category: category,
              );
        },
      ),
    );
  }

  void _showEditGoalSheet(GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _GoalFormSheet(
        initialTitle: goal.title,
        initialDescription: goal.description,
        initialTargetDate: goal.targetDate,
        initialCategory: goal.category,
        onSave: (title, description, targetDate, category) {
          ref.read(goalProvider.notifier).updateGoal(
                id: goal.id,
                title: title,
                description: description,
                targetDate: targetDate,
                category: category,
              );
        },
      ),
    );
  }

  void _confirmDelete(GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(goalProvider.notifier).deleteGoal(goal.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmComplete(GoalModel goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Goal'),
        content: Text('Mark "${goal.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(goalProvider.notifier).updateGoal(
                    id: goal.id,
                    status: 'completed',
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flag, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('My Goals'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.goals.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.flag, size: 48, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 16),
                          const Text('No goals yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddGoalSheet,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Your First Goal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _GoalBanner(onAddGoal: _showAddGoalSheet),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(goalProvider.notifier).loadAllGoals(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      ...state.goals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalCard(
                            goal: goal,
                            onTap: () => _showEditGoalSheet(goal),
                            onComplete: goal.isActive ? () => _confirmComplete(goal) : null,
                            onDelete: () => _confirmDelete(goal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GoalBanner(onAddGoal: _showAddGoalSheet),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _GoalBanner extends StatelessWidget {
  final VoidCallback onAddGoal;

  const _GoalBanner({required this.onAddGoal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Your Goals',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define career, skill & package goals to track your personal growth',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onAddGoal,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Goal', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    this.onComplete,
    required this.onDelete,
  });

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

  Color _urgencyColor(int days) {
    if (goal.isCompleted) return AppColors.success;
    if (days <= 0) return AppColors.error;
    if (days <= 10) return AppColors.warning;
    if (days <= 20) return Colors.orange;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.remainingDays;
    final urgencyColor = _urgencyColor(daysLeft);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              Container(width: 4, height: 88, color: urgencyColor),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      goal.isCompleted ? AppColors.success : urgencyColor,
                      (goal.isCompleted ? AppColors.success : urgencyColor).withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(goal.category),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                                color: goal.isCompleted ? AppColors.textLight : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onComplete != null)
                            IconButton(
                              icon: Icon(Icons.check_circle_outline,
                                  color: AppColors.success, size: 20),
                              onPressed: onComplete,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              goal.isCompleted
                                  ? 'Completed'
                                  : goal.isOverdue
                                      ? 'Overdue'
                                      : '$daysLeft days left',
                              style: TextStyle(
                                color: urgencyColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today, size: 11, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            goal.targetDate,
                            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final String? initialTargetDate;
  final String? initialCategory;
  final void Function(String title, String? description, String targetDate, String category) onSave;

  const _GoalFormSheet({
    this.initialTitle,
    this.initialDescription,
    this.initialTargetDate,
    this.initialCategory,
    required this.onSave,
  });

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _category;
  DateTime? _targetDate;

  final _categories = [
    {'value': 'career', 'label': 'Career', 'icon': Icons.work},
    {'value': 'package', 'label': 'Package', 'icon': Icons.trending_up},
    {'value': 'skill', 'label': 'Skill', 'icon': Icons.school},
    {'value': 'custom', 'label': 'Custom', 'icon': Icons.flag},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _category = widget.initialCategory ?? 'career';
    if (widget.initialTargetDate != null) {
      _targetDate = DateTime.tryParse(widget.initialTargetDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.initialTitle != null ? 'Edit Goal' : 'Add Goal',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Goal title *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: _categories.map((cat) {
              final selected = _category == cat['value'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: cat == _categories.last ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = cat['value'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 20,
                            color: selected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (date != null) setState(() => _targetDate = date);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _targetDate != null
                        ? 'Target: ${formatDate(_targetDate!)}'
                        : 'Set target date *',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty || _targetDate == null) return;
                widget.onSave(
                  _titleController.text.trim(),
                  _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                  _targetDate!.toIso8601String().split('T')[0],
                  _category,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
