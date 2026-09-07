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
      state = LookupState(lookups: [...state.lookups.where((l) => l.lookupCode != 'DOC_TYPE' && !l.lookupCode.startsWith('OFFER') && !l.lookupCode.startsWith('JOINING') && !l.lookupCode.startsWith('INCREMENT') && !l.lookupCode.startsWith('PAYSLIP') && !l.lookupCode.startsWith('CERTIFICATE') && !l.lookupCode.startsWith('RELIEVING') && !l.lookupCode.startsWith('TDS') && !l.lookupCode.startsWith('CONFIRMATION')), ...list.where((l) => l.isActive && !l.isDeleted)]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load types');
    }
  }

  Future<void> loadByCode(String code) async {
    try {
      final res = await _apiClient.get(ApiEndpoints.lookups, queryParameters: {'code': code});
      final list = (res.data as List).map((e) => LookupModel.fromJson(e as Map<String, dynamic>)).toList();
      list.sort((a, b) => a.sortedOrder.compareTo(b.sortedOrder));
      final filtered = list.where((l) => l.isActive && !l.isDeleted).toList();
      // Merge, dedupe by lookupCode
      final existing = {for (var l in state.lookups) l.lookupCode: l};
      for (var l in filtered) existing[l.lookupCode] = l;
      // Also keep parent itself if not in list (some APIs return only children)
      state = state.copyWith(lookups: existing.values.toList(), isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load $code');
    }
  }
}

final lookupProvider = StateNotifierProvider<LookupNotifier, LookupState>((ref) {
  final notifier = LookupNotifier(ref.read(apiClientProvider));
  Future.microtask(() => notifier.loadDocTypes());
  return notifier;
});
