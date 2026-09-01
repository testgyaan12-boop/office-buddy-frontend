import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import '../documents/models/document_model.dart' show DocumentModel, parseDocumentList;

class DashboardStats {
  final int totalDocuments;
  final int totalCompanies;
  final int experienceYears;
  final int totalCertificates;

  const DashboardStats({
    this.totalDocuments = 0,
    this.totalCompanies = 0,
    this.experienceYears = 0,
    this.totalCertificates = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalDocuments: json['totalDocuments'] as int? ?? 0,
        totalCompanies: json['totalCompanies'] as int? ?? 0,
        experienceYears: json['experienceYears'] as int? ?? 0,
        totalCertificates: json['totalCertificates'] as int? ?? 0,
      );
}

class DashboardState {
  final bool isLoading;
  final String? error;
  final DashboardStats? stats;
  final List<DocumentModel> recentDocuments;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.stats,
    this.recentDocuments = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardStats? stats,
    List<DocumentModel>? recentDocuments,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      recentDocuments: recentDocuments ?? this.recentDocuments,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _apiClient;

  DashboardNotifier(this._apiClient) : super(const DashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statsResponse = await _apiClient.get(ApiEndpoints.dashboardStats);
      final docsResponse = await _apiClient.get(
        ApiEndpoints.documents,
        queryParameters: {'limit': 5},
      );
      state = DashboardState(
        isLoading: false,
        stats: DashboardStats.fromJson(statsResponse.data),
        recentDocuments: parseDocumentList(docsResponse.data),
      );
    } catch (e) {
      state = const DashboardState(
        isLoading: false,
        stats: DashboardStats(),
        recentDocuments: [],
      );
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  final notifier = DashboardNotifier(ref.read(apiClientProvider));
  Future.microtask(() => notifier.loadDashboard());
  return notifier;
});
