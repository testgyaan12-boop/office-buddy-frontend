import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/lookup_model.dart';

class LookupState {
  final bool isLoading;
  final String? error;
  final List<LookupModel> lookups;

  const LookupState({this.isLoading = false, this.error, this.lookups = const []});

  LookupState copyWith({bool? isLoading, String? error, List<LookupModel>? lookups}) {
    return LookupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lookups: lookups ?? this.lookups,
    );
  }
}

class LookupNotifier extends StateNotifier<LookupState> {
  final ApiClient _apiClient;
  LookupNotifier(this._apiClient) : super(const LookupState());

  Future<void> loadDocTypes() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.get(ApiEndpoints.lookups, queryParameters: {'code': 'DOC_TYPE'});
      final list = (res.data as List).map((e) => LookupModel.fromJson(e as Map<String, dynamic>)).toList();
      list.sort((a, b) => a.sortedOrder.compareTo(b.sortedOrder));
      state = LookupState(lookups: list.where((l) => l.isActive && !l.isDeleted).toList());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load types');
    }
  }
}

final lookupProvider = StateNotifierProvider<LookupNotifier, LookupState>((ref) {
  final notifier = LookupNotifier(ref.read(apiClientProvider));
  Future.microtask(() => notifier.loadDocTypes());
  return notifier;
});
