import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import 'models/company_model.dart';

class CompaniesState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<CompanyModel> companies;

  const CompaniesState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.companies = const [],
  });

  CompaniesState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    List<CompanyModel>? companies,
  }) {
    return CompaniesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      companies: companies ?? this.companies,
    );
  }
}

class CompaniesNotifier extends StateNotifier<CompaniesState> {
  final ApiClient _apiClient;

  CompaniesNotifier(this._apiClient) : super(const CompaniesState());

  Future<void> loadCompanies() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(ApiEndpoints.companies);
      final companies = (response.data as List)
          .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = CompaniesState(companies: companies);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load companies',
      );
    }
  }

  Future<CompanyModel?> getCompanyById(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.companies}/$id');
      return CompanyModel.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> addCompany(CompanyModel company) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiClient.post(
        ApiEndpoints.companies,
        data: company.toJson(),
      );
      await loadCompanies();
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to add company');
    }
  }

  Future<void> updateCompany(String id, CompanyModel company) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiClient.put(
        '${ApiEndpoints.companies}/$id',
        data: company.toJson(),
      );
      await loadCompanies();
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to update company');
    }
  }

  Future<void> deleteCompany(String id) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _apiClient.delete('${ApiEndpoints.companies}/$id');
      await loadCompanies();
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to delete company');
    }
  }
}

final companiesProvider =
    StateNotifierProvider<CompaniesNotifier, CompaniesState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  final notifier = CompaniesNotifier(ref.read(apiClientProvider));
  Future.microtask(() => notifier.loadCompanies());
  return notifier;
});
