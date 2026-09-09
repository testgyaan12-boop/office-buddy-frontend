import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

class StorageQuota {
  final int allocatedBytes;
  final int usedBytes;
  final int remainingBytes;
  final int usagePercentage;
  final String planCode;
  final String planName;

  StorageQuota({
    required this.allocatedBytes,
    required this.usedBytes,
    required this.remainingBytes,
    required this.usagePercentage,
    required this.planCode,
    required this.planName,
  });

  factory StorageQuota.fromJson(Map<String, dynamic> j) => StorageQuota(
        allocatedBytes: (j['allocatedBytes'] as num).toInt(),
        usedBytes: (j['usedBytes'] as num).toInt(),
        remainingBytes: (j['remainingBytes'] as num).toInt(),
        usagePercentage: (j['usagePercentage'] as num).toInt(),
        planCode: j['planCode'] as String? ?? 'FREE',
        planName: j['planName'] as String? ?? 'Free',
      );

  String get formattedAllocated => _fmt(allocatedBytes);
  String get formattedUsed => _fmt(usedBytes);
  String get formattedRemaining => _fmt(remainingBytes);

  static String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class StorageQuotaState {
  final StorageQuota? quota;
  final bool isLoading;
  final String? error;
  const StorageQuotaState({this.quota, this.isLoading = false, this.error});
  StorageQuotaState copyWith({StorageQuota? quota, bool? isLoading, String? error}) =>
      StorageQuotaState(quota: quota ?? this.quota, isLoading: isLoading ?? this.isLoading, error: error);
}

class StorageQuotaNotifier extends StateNotifier<StorageQuotaState> {
  final ApiClient _api;
  StorageQuotaNotifier(this._api) : super(const StorageQuotaState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.get(ApiEndpoints.storageQuota);
      state = StorageQuotaState(quota: StorageQuota.fromJson(r.data as Map<String, dynamic>));
    } catch (e) {
      state = StorageQuotaState(error: e.toString());
    }
  }
}

final storageQuotaProvider = StateNotifierProvider<StorageQuotaNotifier, StorageQuotaState>((ref) {
  // Recreate per login user so quota never shows previous user's numbers.
  ref.watch(authProvider.select((s) => s.user?.id));
  return StorageQuotaNotifier(ref.read(apiClientProvider));
});
