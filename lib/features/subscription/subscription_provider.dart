import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatAmount(int paise, String currency) {
  if (paise == 0) return 'Free';
  final symbol = currency == 'INR' ? '\u20B9' : '$currency ';
  final v = paise / 100;
  return v == v.truncateToDouble()
      ? '$symbol${v.toStringAsFixed(0)}'
      : '$symbol${v.toStringAsFixed(2)}';
}

class PlanInfo {
  final int id;
  final String planName;
  final String planCode;
  final String period;
  final int allocatedBytes;
  final String allocatedUnit;
  final int amountPaise;
  final String currency;

  PlanInfo({
    required this.id,
    required this.planName,
    required this.planCode,
    required this.period,
    required this.allocatedBytes,
    required this.allocatedUnit,
    required this.amountPaise,
    required this.currency,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> j) => PlanInfo(
        id: (j['id'] as num).toInt(),
        planName: j['planName'] as String? ?? '',
        planCode: j['planCode'] as String? ?? '',
        period: j['period'] as String? ?? '',
        allocatedBytes: (j['allocatedBytes'] as num?)?.toInt() ?? 0,
        allocatedUnit: j['allocatedUnit'] as String? ?? '',
        amountPaise: (j['amountPaise'] as num?)?.toInt() ?? 0,
        currency: j['currency'] as String? ?? 'INR',
      );

  String get storageLabel => formatBytes(allocatedBytes);
  String get priceLabel => formatAmount(amountPaise, currency);
  bool get isFree => amountPaise == 0;
}

class SubscriptionInfo {
  final String planCode;
  final String planName;
  final String status;
  final String? razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String? razorpayKeyId;
  final String? expiryDate;
  final String paymentProvider;

  SubscriptionInfo({
    required this.planCode,
    required this.planName,
    required this.status,
    this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    this.razorpayKeyId,
    this.expiryDate,
    this.paymentProvider = 'razorpay',
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) => SubscriptionInfo(
        planCode: j['planCode'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        status: j['status'] as String? ?? '',
        razorpayOrderId: j['razorpayOrderId'] as String?,
        amountPaise: (j['amountPaise'] as num?)?.toInt() ?? 0,
        currency: j['currency'] as String? ?? 'INR',
        razorpayKeyId: j['razorpayKeyId'] as String?,
        expiryDate: j['expiryDate'] as String?,
        paymentProvider: (j['paymentProvider'] as String?)?.toLowerCase() ?? 'razorpay',
      );
}

class InvoiceInfo {
  final String id;
  final String invoiceNo;
  final String planName;
  final int amountPaise;
  final String currency;
  final String status;
  final String? issuedAt;
  final String? razorpayPaymentId;

  InvoiceInfo({
    required this.id,
    required this.invoiceNo,
    required this.planName,
    required this.amountPaise,
    required this.currency,
    required this.status,
    this.issuedAt,
    this.razorpayPaymentId,
  });

  factory InvoiceInfo.fromJson(Map<String, dynamic> j) => InvoiceInfo(
        id: j['id'] as String? ?? '',
        invoiceNo: j['invoiceNo'] as String? ?? '',
        planName: j['planName'] as String? ?? '',
        amountPaise: (j['amountPaise'] as num?)?.toInt() ?? 0,
        currency: j['currency'] as String? ?? 'INR',
        status: j['status'] as String? ?? '',
        issuedAt: j['issuedAt'] as String?,
        razorpayPaymentId: j['razorpayPaymentId'] as String?,
      );

  String get priceLabel => formatAmount(amountPaise, currency);
}

class SubscriptionState {
  final bool isLoading;
  final String? error;
  final List<PlanInfo> plans;
  final SubscriptionInfo? current;
  final List<InvoiceInfo> invoices;

  const SubscriptionState({
    this.isLoading = false,
    this.error,
    this.plans = const [],
    this.current,
    this.invoices = const [],
  });

  SubscriptionState copyWith({
    bool? isLoading,
    String? error,
    List<PlanInfo>? plans,
    SubscriptionInfo? current,
    List<InvoiceInfo>? invoices,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      plans: plans ?? this.plans,
      current: current ?? this.current,
      invoices: invoices ?? this.invoices,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiClient _api;
  final Ref _ref;

  SubscriptionNotifier(this._api, this._ref) : super(const SubscriptionState());

  String? get userEmail => _ref.read(authProvider).user?.email;

  Future<void> loadAll() async {
    await Future.wait([loadPlans(), loadCurrent(), loadInvoices()]);
  }

  Future<void> loadPlans() async {
    try {
      final r = await _api.get(ApiEndpoints.plans);
      final list = (r.data as List)
          .map((e) => PlanInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(plans: list, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load plans');
    }
  }

  Future<void> loadCurrent() async {
    try {
      final r = await _api.get(ApiEndpoints.subCurrent);
      if (r.data == null || (r.data is String && (r.data as String).isEmpty)) {
        state = state.copyWith(current: null);
        return;
      }
      state = state.copyWith(
        current: SubscriptionInfo.fromJson(r.data as Map<String, dynamic>),
      );
    } catch (e) {
      state = state.copyWith(current: null);
    }
  }

  Future<SubscriptionInfo?> createOrder({required String planCode, required String planName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _api.post(
        ApiEndpoints.subCreateOrder,
        data: {'planCode': planCode, 'planName': planName},
      );
      final order = SubscriptionInfo.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(isLoading: false);
      return order;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planCode,
    required String planName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        ApiEndpoints.subVerify,
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'planCode': planCode,
          'planName': planName,
        },
      );
      await loadCurrent();
      await loadInvoices();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
      return false;
    }
  }

  Future<void> loadInvoices() async {
    try {
      final r = await _api.get(ApiEndpoints.invoicesMe);
      final list = (r.data as List)
          .map((e) => InvoiceInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(invoices: list);
    } catch (_) {}
  }

  Future<Uint8List?> downloadInvoiceBytes(InvoiceInfo inv) async {
    try {
      final bytes = await _api.downloadBytes(ApiEndpoints.invoicePdf(inv.id));
      if (bytes.isEmpty) return null;
      return bytes;
    } catch (e) {
      state = state.copyWith(error: 'Failed to download invoice: ${_msg(e)}');
      return null;
    }
  }

  Future<String?> downloadInvoicePdf(InvoiceInfo inv) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${inv.invoiceNo}.pdf';
      await _api.downloadFile(ApiEndpoints.invoicePdf(inv.id), path);
      return path;
    } catch (e) {
      state = state.copyWith(error: 'Failed to download invoice');
      return null;
    }
  }

  String _msg(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final m = e.response!.data as Map;
      if (m['message'] is String) return m['message'] as String;
      if (m['error'] is String) return m['error'] as String;
    }
    return 'Something went wrong. Please try again.';
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return SubscriptionNotifier(ref.read(apiClientProvider), ref);
});
