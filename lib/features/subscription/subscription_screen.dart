import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../storage/storage_quota_provider.dart';
import 'checkout_opener_stub.dart'
    if (dart.library.js_interop) 'checkout_opener_web.dart';
import 'invoice_save_stub.dart'
    if (dart.library.js_interop) 'invoice_save_web.dart';
import 'subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  late final Razorpay _razorpay;
  PlanInfo? _pendingPlan;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    Future.microtask(() => ref.read(subscriptionProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _buy(PlanInfo plan) async {
    if (plan.isFree || _paying) return;
    setState(() => _paying = true);
    final order = await ref.read(subscriptionProvider.notifier).createOrder(planCode: plan.planCode, planName: plan.planName);
    if (!mounted) return;
    setState(() => _paying = false);
    if (order == null || order.razorpayOrderId == null) {
      final err = ref.read(subscriptionProvider).error ?? 'Failed to create order';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
      return;
    }
    final keyId = order.razorpayKeyId ?? '';
    final orderId = order.razorpayOrderId ?? '';
    if (keyId.isEmpty || keyId == 'rzp_test_dummy' || orderId.startsWith('order_mock_')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment gateway not configured. Set real Razorpay test keys on backend.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    _pendingPlan = plan;
    final checkoutOptions = <String, Object?>{
      'key': keyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': 'OfficeBuddy',
      'description': '${plan.planName} plan',
      'order_id': orderId,
      'prefill': {'email': ref.read(subscriptionProvider.notifier).userEmail ?? ''},
    };
    if (kIsWeb) {
      try {
        await openWebCheckout(
          options: checkoutOptions,
          onSuccess: (oid, pid, sig) => _verifyAndActivate(oid, pid, sig),
          onError: (msg) {
            _pendingPlan = null;
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed: $msg'), backgroundColor: AppColors.error),
            );
          },
          onDismiss: () => _pendingPlan = null,
        );
      } catch (e) {
        _pendingPlan = null;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment page: $e'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    try {
      _razorpay.open(Map<String, dynamic>.from(checkoutOptions));
    } catch (e) {
      _pendingPlan = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open payment page: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    await _verifyAndActivate(r.orderId ?? '', r.paymentId ?? '', r.signature ?? '');
  }

  Future<void> _verifyAndActivate(String orderId, String paymentId, String signature) async {
    final ok = await ref.read(subscriptionProvider.notifier).verifyPayment(
          orderId: orderId,
          paymentId: paymentId,
          signature: signature,
          planCode: _pendingPlan?.planCode ?? '',
          planName: _pendingPlan?.planName ?? '',
        );
    _pendingPlan = null;
    if (!mounted) return;
    if (ok) {
      ref.read(storageQuotaProvider.notifier).load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated!'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(subscriptionProvider).error ?? 'Payment verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    _pendingPlan = null;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${r.message ?? 'cancelled'}'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse r) {}

  void _invoiceError() {
    final err = ref.read(subscriptionProvider).error ?? 'Failed to download invoice';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: AppColors.error),
    );
  }

  Future<void> _openInvoice(InvoiceInfo inv) async {
    if (kIsWeb) {
      final bytes = await ref.read(subscriptionProvider.notifier).downloadInvoiceBytes(inv);
      if (!mounted) return;
      if (bytes == null) {
        _invoiceError();
        return;
      }
      try {
        await savePdfInBrowser(bytes, '${inv.invoiceNo}.pdf');
      } catch (e) {
        if (!mounted) return;
        _invoiceError();
      }
      return;
    }
    final path = await ref.read(subscriptionProvider.notifier).downloadInvoicePdf(inv);
    if (!mounted) return;
    if (path == null) {
      _invoiceError();
      return;
    }
    await OpenFilex.open(path);
  }

  Future<void> _shareInvoice(InvoiceInfo inv) async {
    if (kIsWeb) {
      await _openInvoice(inv);
      return;
    }
    final path = await ref.read(subscriptionProvider.notifier).downloadInvoicePdf(inv);
    if (!mounted || path == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'OfficeBuddy invoice ${inv.invoiceNo}'));
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final quota = ref.watch(storageQuotaProvider).quota;
    final currentCode = sub.current?.planCode ?? quota?.planCode ?? 'FREE';

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(subscriptionProvider.notifier).loadAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (sub.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(sub.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            const Text('Plans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (sub.plans.isEmpty && !sub.isLoading)
              const Text('No plans available', style: TextStyle(color: AppColors.textSecondary)),
            ...sub.plans.map((p) {
              final isCurrent = p.planCode == currentCode;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : AppColors.primary.withValues(alpha: 0.12),
                    width: isCurrent ? 1.5 : 1,
                  ),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(p.planName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              if (isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Current', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${p.storageLabel} storage', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(p.priceLabel, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    if (!isCurrent && !p.isFree)
                      ElevatedButton(
                        onPressed: (_paying || sub.isLoading) ? null : () => _buy(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _paying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Buy'),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text('Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (sub.invoices.isEmpty)
              const Text('No invoices yet', style: TextStyle(color: AppColors.textSecondary)),
            ...sub.invoices.map((inv) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                    title: Text(inv.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${inv.planName} • ${inv.priceLabel}', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 20),
                          onPressed: () => _shareInvoice(inv),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => _openInvoice(inv),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
