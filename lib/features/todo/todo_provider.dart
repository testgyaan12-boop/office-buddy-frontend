import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/todo_model.dart';

class TodoState {
  final List<TodoModel> todos;
  final bool isLoading;
  final String? error;

  const TodoState({
    this.todos = const [],
    this.isLoading = false,
    this.error,
  });

  TodoState copyWith({
    List<TodoModel>? todos,
    bool? isLoading,
    String? error,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TodoNotifier extends StateNotifier<TodoState> {
  final ApiClient _apiClient;
  String? _currentType;
  String? _currentSearch;
  String? _currentDate;

  TodoNotifier(this._apiClient) : super(const TodoState());

  Future<void> loadTodos({
    String? type,
    String? search,
    String? date,
    String? goalId,
  }) async {
    _currentType = type;
    _currentSearch = search;
    _currentDate = date;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (type != null) params['type'] = type;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (date != null) params['date'] = date;
      if (goalId != null) params['goalId'] = goalId;

      final response = await _apiClient.get(
        ApiEndpoints.todos,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final list = (response.data as List)
          .map((e) => TodoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = TodoState(todos: list);
    } catch (e) {
      state = TodoState(error: 'Failed to load todos');
    }
  }

  Future<void> createTodo({
    required String title,
    String? content,
    required String type,
    String? dueDate,
    String? goalId,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.todos,
        data: {
          'title': title,
          'content': content,
          'type': type,
          'dueDate': dueDate,
          'goalId': goalId,
        },
      );
      await loadTodos(type: _currentType, search: _currentSearch, date: _currentDate);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create todo');
    }
  }

  Future<void> updateTodo({
    required String id,
    String? title,
    String? content,
    String? dueDate,
    bool? completed,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (dueDate != null) data['dueDate'] = dueDate;
      if (completed != null) data['completed'] = completed;

      await _apiClient.put('${ApiEndpoints.todos}/$id', data: data);
      await loadTodos(type: _currentType, search: _currentSearch, date: _currentDate);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update todo');
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.todos}/$id');
      await loadTodos(type: _currentType, search: _currentSearch, date: _currentDate);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete todo');
    }
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  return TodoNotifier(ref.read(apiClientProvider));
});
