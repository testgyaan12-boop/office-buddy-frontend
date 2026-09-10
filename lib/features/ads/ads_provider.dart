import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

class AdConfigModel {
  final int id;
  final String providerName;
  final String platform;
  final String adType;
  final String placement;
  final String adUnitId;
  final String appId;

  AdConfigModel({
    required this.id,
    required this.providerName,
    required this.platform,
    required this.adType,
    required this.placement,
    required this.adUnitId,
    required this.appId,
  });

  factory AdConfigModel.fromJson(Map<String, dynamic> j) => AdConfigModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        providerName: j['providerName'] as String? ?? '',
        platform: j['platform'] as String? ?? '',
        adType: j['adType'] as String? ?? '',
        placement: j['placement'] as String? ?? '',
        adUnitId: j['adUnitId'] as String? ?? '',
        appId: j['appId'] as String? ?? '',
      );
}

class AdsNotifier extends StateNotifier<AdConfigModel?> {
  final ApiClient _api;

  AdsNotifier(this._api) : super(null) {
    loadHomeAd();
  }

  static String get platform {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  Future<void> loadHomeAd() async {
    try {
      final r = await _api.get(
        ApiEndpoints.adsConfig,
        queryParameters: {
          'platform': platform,
          'placement': 'home_banner',
          'adType': 'banner',
        },
      );
      if (r.data == null || (r.data is String && (r.data as String).isEmpty)) {
        debugPrint('[ads] no ad: 204/empty (paid user or no matching config)');
        state = null;
        return;
      }
      final ad = AdConfigModel.fromJson(r.data as Map<String, dynamic>);
      state = ad;
      _logImpression(ad);
    } catch (e) {
      debugPrint('[ads] load failed: $e');
      state = null;
    }
  }

  Future<void> _logImpression(AdConfigModel ad) async {
    try {
      await _api.post(ApiEndpoints.adsLog, data: {
        'provider': ad.providerName,
        'placement': ad.placement,
        'adType': ad.adType,
        'status': 'SHOWN',
      });
    } catch (_) {}
  }
}

final adsProvider =
    StateNotifierProvider<AdsNotifier, AdConfigModel?>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return AdsNotifier(ref.read(apiClientProvider));
});
