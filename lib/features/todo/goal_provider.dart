import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import 'models/goal_model.dart';

class GoalState {
  final List<GoalModel> goals;
  final List<GoalModel> dashboardGoals;
  final bool isLoading;
  final String? error;

  const GoalState({
    this.goals = const [],
    this.dashboardGoals = const [],
    this.isLoading = false,
    this.error,
  });

  GoalState copyWith({
    List<GoalModel>? goals,
    List<GoalModel>? dashboardGoals,
    bool? isLoading,
    String? error,
  }) {
    return GoalState(
      goals: goals ?? this.goals,
      dashboardGoals: dashboardGoals ?? this.dashboardGoals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GoalNotifier extends StateNotifier<GoalState> {
  final ApiClient _apiClient;

  GoalNotifier(this._apiClient) : super(const GoalState());

  Future<void> loadDashboardGoals() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.goalsDashboard);
      final list = (response.data as List)
          .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(dashboardGoals: list);
    } catch (_) {}
  }

  Future<void> loadAllGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(ApiEndpoints.goals);
      final list = (response.data as List)
          .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(goals: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load goals');
    }
  }

  Future<void> createGoal({
    required String title,
    String? description,
    required String targetDate,
    required String category,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.goals,
        data: {
          'title': title,
          'description': description,
          'targetDate': targetDate,
          'category': category,
        },
      );
      await loadAllGoals();
      await loadDashboardGoals();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create goal');
    }
  }

  Future<void> updateGoal({
    required String id,
    String? title,
    String? description,
    String? targetDate,
    String? category,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (targetDate != null) data['targetDate'] = targetDate;
      if (category != null) data['category'] = category;
      if (status != null) data['status'] = status;

      await _apiClient.put('${ApiEndpoints.goals}/$id', data: data);
      await loadAllGoals();
      await loadDashboardGoals();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update goal');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.goals}/$id');
      await loadAllGoals();
      await loadDashboardGoals();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete goal');
    }
  }
}

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  final notifier = GoalNotifier(ref.read(apiClientProvider));
  Future.microtask(() => notifier.loadDashboardGoals());
  return notifier;
});
