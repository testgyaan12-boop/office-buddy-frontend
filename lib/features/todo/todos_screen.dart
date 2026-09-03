import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/date_badge.dart';
import '../../core/constants/app_colors.dart';
import 'models/todo_model.dart';
import 'todo_provider.dart';

class TodosScreen extends ConsumerStatefulWidget {
  const TodosScreen({super.key});

  @override
  ConsumerState<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends ConsumerState<TodosScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(todoProvider.notifier).loadTodos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(todoProvider.notifier).loadTodos(
          search: query.isEmpty ? null : query,
          type: _selectedFilter == 'all' ? null : _selectedFilter,
          date: _selectedDate?.toIso8601String().split('T')[0],
        );
  }

  void _onFilterChange(String filter) {
    setState(() => _selectedFilter = filter);
    ref.read(todoProvider.notifier).loadTodos(
          type: filter == 'all' ? null : filter,
          search: _searchController.text.isEmpty ? null : _searchController.text,
          date: _selectedDate?.toIso8601String().split('T')[0],
        );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      ref.read(todoProvider.notifier).loadTodos(
            date: date.toIso8601String().split('T')[0],
            type: _selectedFilter == 'all' ? null : _selectedFilter,
          );
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    ref.read(todoProvider.notifier).loadTodos(
          type: _selectedFilter == 'all' ? null : _selectedFilter,
          search: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TodoFormSheet(
        onSave: (title, content, type, dueDate) {
          ref.read(todoProvider.notifier).createTodo(
                title: title,
                content: content,
                type: type,
                dueDate: dueDate,
              );
        },
      ),
    );
  }

  void _showEditSheet(TodoModel todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TodoFormSheet(
        initialTitle: todo.title,
        initialContent: todo.content,
        initialType: todo.type,
        initialDueDate: todo.dueDate,
        onSave: (title, content, type, dueDate) {
          ref.read(todoProvider.notifier).updateTodo(
                id: todo.id,
                title: title,
                content: content,
                dueDate: dueDate,
              );
        },
      ),
    );
  }

  void _confirmDelete(TodoModel todo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (ctx2, ref2, _) {
          final saving = ref2.watch(todoProvider).savingId == todo.id;
          return AlertDialog(
            title: const Text('Delete'),
            content: Text('Delete "${todo.title}"?'),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        await ref.read(todoProvider.notifier).deleteTodo(todo.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks & notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: _onSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedFilter == 'all',
                  onTap: () => _onFilterChange('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tasks',
                  selected: _selectedFilter == 'task',
                  onTap: () => _onFilterChange('task'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Notes',
                  selected: _selectedFilter == 'note',
                  onTap: () => _onFilterChange('note'),
                ),
                const Spacer(),
                if (_selectedDate != null)
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DateBadge(formatDate(_selectedDate!), fontSize: 12),
                          const SizedBox(width: 4),
                          const Icon(Icons.close, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (state.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.todos.isEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                    Icon(Icons.checklist, size: 64, color: AppColors.textLight),
                    const SizedBox(height: 16),
                    const Text('No items yet', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task or Note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _TodoBanner(onAddTodo: _showAddSheet),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(todoProvider.notifier).loadTodos(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    ...state.todos.map((todo) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TodoItem(
                        todo: todo,
                        onToggle: () {
                          ref.read(todoProvider.notifier).updateTodo(
                                id: todo.id,
                                completed: !todo.completed,
                              );
                        },
                        onTap: () => _showEditSheet(todo),
                        onDelete: () => _confirmDelete(todo),
                      ),
                    )),
                    const SizedBox(height: 12),
                    _TodoBanner(onAddTodo: _showAddSheet),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TodoBanner extends StatelessWidget {
  final VoidCallback onAddTodo;

  const _TodoBanner({required this.onAddTodo});

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
            child: const Icon(Icons.checklist, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Tasks & Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your daily to-dos and jot down important notes',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onAddTodo,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
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

class _TodoItem extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TodoItem({
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  Color get _typeColor => todo.isTask ? AppColors.primary : Colors.amber.shade700;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
              Container(width: 4, height: 80, color: _typeColor),
              const SizedBox(width: 12),
              if (todo.isTask)
                Consumer(
                  builder: (context, ref, _) {
                    final saving = ref.watch(todoProvider).savingId == todo.id;
                    return saving
                        ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : GestureDetector(
                            onTap: onToggle,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: todo.completed ? AppColors.success : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: todo.completed ? AppColors.success : AppColors.textLight,
                                  width: 1.5,
                                ),
                              ),
                              child: todo.completed ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                            ),
                          );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.note_outlined, color: _typeColor, size: 20),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              todo.isTask ? 'Task' : 'Note',
                              style: TextStyle(
                                color: _typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Consumer(
                            builder: (context, ref, _) {
                              final saving = ref.watch(todoProvider).savingId == todo.id;
                              return saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                      onPressed: onDelete,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: todo.completed ? TextDecoration.lineThrough : null,
                          color: todo.completed ? AppColors.textLight : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (todo.content != null && todo.content!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          todo.content!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (todo.dueDate != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 11, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${todo.dueDate}',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _TodoFormSheet extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? initialType;
  final String? initialDueDate;
  final void Function(String title, String? content, String type, String? dueDate) onSave;

  const _TodoFormSheet({
    this.initialTitle,
    this.initialContent,
    this.initialType,
    this.initialDueDate,
    required this.onSave,
  });

  @override
  State<_TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<_TodoFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _type;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _type = widget.initialType ?? 'task';
    if (widget.initialDueDate != null) {
      _dueDate = DateTime.tryParse(widget.initialDueDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
            widget.initialTitle != null ? 'Edit' : 'Add',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  label: 'Task',
                  icon: Icons.check_box,
                  selected: _type == 'task',
                  onTap: () => setState(() => _type = 'task'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  label: 'Note',
                  icon: Icons.note,
                  selected: _type == 'note',
                  onTap: () => setState(() => _type = 'note'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Content (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (date != null) setState(() => _dueDate = date);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dueDate != null
                        ? formatDate(_dueDate!)
                        : 'Due date',
                  ),
                ),
              ),
              if (_dueDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _dueDate = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Consumer(
            builder: (context, ref, _) {
              final isSaving = ref.watch(todoProvider).savingId != null;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          if (_titleController.text.trim().isEmpty) return;
                          widget.onSave(
                            _titleController.text.trim(),
                            _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
                            _type,
                            _dueDate?.toIso8601String().split('T')[0],
                          );
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (context.mounted && ref.read(todoProvider).savingId == null) Navigator.pop(context);
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
