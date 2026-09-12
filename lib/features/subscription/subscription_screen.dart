import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/loading_shimmer.dart';
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
  String? _buyingCode;

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
    setState(() {
      _paying = true;
      _buyingCode = plan.planCode;
    });
    final order = await ref.read(subscriptionProvider.notifier).createOrder(planCode: plan.planCode, planName: plan.planName);
    if (!mounted) return;
    setState(() {
      _paying = false;
      _buyingCode = null;
    });
    if (order == null || order.razorpayOrderId == null) {
      final err = ref.read(subscriptionProvider).error ?? 'Failed to create order';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
      return;
    }
    final provider = order.paymentProvider;
    if (provider != 'razorpay') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider.isEmpty ? 'This' : provider[0].toUpperCase() + provider.substring(1)} payments coming soon. Razorpay is the active gateway.'),
          backgroundColor: AppColors.error,
        ),
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
    // Razorpay checkout demands paise; order.amount is rupees
    final checkoutOptions = <String, Object?>{
      'key': keyId,
      'amount': (order.amount * 100).round(),
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
    final cs = Theme.of(context).colorScheme;
    final currentCode = sub.current?.planCode ?? quota?.planCode ?? 'FREE';
    final isInitialLoading = sub.isLoading &&
        sub.plans.isEmpty &&
        sub.invoices.isEmpty &&
        sub.current == null &&
        quota == null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) context.pop();
          },
        ),
        title: const Text('Subscription'),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(subscriptionProvider.notifier).loadAll(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(subscriptionProvider.notifier).loadAll(),
        child: isInitialLoading
            ? const LoadingShimmer(itemCount: 5)
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sub.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(sub.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => ref.read(subscriptionProvider.notifier).loadAll(),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    _CurrentPlanHero(
                      current: sub.current,
                      quotaUsedBytes: quota?.usedBytes,
                      quotaAllocatedBytes: quota?.allocatedBytes,
                      fallbackAllocatedBytes: _planStorageFor(sub.plans, currentCode),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Choose a plan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade your storage and unlock more capacity.',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    if (sub.plans.isEmpty && !sub.isLoading)
                      Text('No plans available', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                    ...sub.plans.map((p) => _PlanCard(
                          plan: p,
                          isCurrent: p.planCode == currentCode,
                          isBusy: (_paying && _buyingCode == p.planCode) || sub.isLoading,
                          busyLabel: _paying && _buyingCode == p.planCode,
                          onBuy: () => _buy(p),
                        )),
                    const SizedBox(height: 26),
                    Text(
                      'Invoices',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your recent billing history',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    if (sub.invoices.isEmpty)
                      _EmptyInvoices()
                    else
                      ...sub.invoices.map((inv) => _InvoiceTile(
                            invoice: inv,
                            onOpen: () => _openInvoice(inv),
                            onShare: () => _shareInvoice(inv),
                          )),
                  ],
                ),
              ),
      ),
    );
  }

  int? _planStorageFor(List<PlanInfo> plans, String code) {
    for (final p in plans) {
      if (p.planCode == code) return p.allocatedBytes;
    }
    return null;
  }
}

class _CurrentPlanHero extends StatelessWidget {
  final SubscriptionInfo? current;
  final int? quotaUsedBytes;
  final int? quotaAllocatedBytes;
  final int? fallbackAllocatedBytes;

  const _CurrentPlanHero({
    required this.current,
    required this.quotaUsedBytes,
    required this.quotaAllocatedBytes,
    required this.fallbackAllocatedBytes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final code = current?.planCode ?? 'FREE';
    final planName = current?.planName ?? '';
    final name = planName.isNotEmpty ? planName : 'Your current plan';

    final hasQuota = quotaUsedBytes != null && quotaAllocatedBytes != null && quotaAllocatedBytes! > 0;
    final percent = hasQuota ? (quotaUsedBytes! / quotaAllocatedBytes!).clamp(0.0, 1.0) : 0.0;
    final usedLabel = hasQuota ? formatBytes(quotaUsedBytes!) : null;
    String? totalLabel;
    if (hasQuota) {
      totalLabel = formatBytes(quotaAllocatedBytes!);
    } else if (fallbackAllocatedBytes != null && fallbackAllocatedBytes! > 0) {
      totalLabel = formatBytes(fallbackAllocatedBytes!);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PLAN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  code,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface),
                ),
              ),
              if (current != null) _StatusBadge(status: current!.status),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Text(name, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 16),
          if (hasQuota) ...[
            Text(
              '${formatBytes(quotaUsedBytes!)} STORAGE USED',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 250),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$usedLabel of $totalLabel',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ] else if (totalLabel != null) ...[
            Text(
              '$totalLabel STORAGE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              totalLabel,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ] else ...[
            Text(
              'Storage details unavailable',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final key = status.toUpperCase();
    final Color color;
    if (key == 'ACTIVE' || key == 'PAID') {
      color = AppColors.success;
    } else if (key == 'PENDING') {
      color = AppColors.warning;
    } else if (key == 'EXPIRED' || key == 'FAILED') {
      color = AppColors.error;
    } else {
      color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(
            status.isEmpty ? '—' : '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final bool isCurrent;
  final bool isBusy;
  final bool busyLabel;
  final VoidCallback onBuy;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isBusy,
    required this.busyLabel,
    required this.onBuy,
  });

  String _periodSuffix(String period) {
    final p = period.toUpperCase();
    if (p.contains('MONTH')) return 'month';
    if (p.contains('YEAR')) return 'year';
    if (p.contains('LIFE')) return 'one-time';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suffix = _periodSuffix(plan.period);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? AppColors.primary.withValues(alpha: 0.45) : cs.outlineVariant.withValues(alpha: 0.6),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.planName.toUpperCase(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: cs.onSurface),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('CURRENT PLAN', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.priceLabel,
                style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
              if (suffix.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5, left: 4),
                  child: Text('/ $suffix', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _PlanFeatureRow(icon: Icons.storage_rounded, text: '${plan.storageLabel} storage'),
          const SizedBox(height: 8),
          _PlanFeatureRow(icon: Icons.calendar_month_rounded, text: plan.period.isEmpty ? 'Recurring billing' : 'Billed ${suffix.isEmpty ? plan.period.toLowerCase() : 'per $suffix'}'),
          const SizedBox(height: 16),
          if (isCurrent)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Current Plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            )
          else if (!plan.isFree)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isBusy ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: busyLabel
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                          SizedBox(width: 10),
                          Text('Processing...'),
                        ],
                      )
                    : Text('Buy ${plan.planName}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PlanFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check, color: AppColors.success, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        ),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceInfo invoice;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  const _InvoiceTile({required this.invoice, required this.onOpen, required this.onShare});

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso.length >= 10 ? iso.substring(0, 10) : iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = _formatDate(invoice.issuedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.invoiceNo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface),
                            ),
                          ),
                          _StatusBadge(status: invoice.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${invoice.planName} • ${invoice.priceLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(date, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20),
                      tooltip: 'Share invoice',
                      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                      padding: EdgeInsets.zero,
                      color: cs.onSurfaceVariant,
                      onPressed: onShare,
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      tooltip: 'Download invoice',
                      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                      padding: EdgeInsets.zero,
                      color: cs.onSurfaceVariant,
                      onPressed: onOpen,
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInvoices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 30, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text('No invoices yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Your invoices will appear here after your first payment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
