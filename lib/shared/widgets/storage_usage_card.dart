import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../features/storage/storage_quota_provider.dart';
import 'package:go_router/go_router.dart';

class StorageUsageCard extends ConsumerWidget {
  final bool compact;
  const StorageUsageCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storageQuotaProvider);
    final q = state.quota;
    if (compact) {
      if (q == null) {
        if (state.isLoading) {
          return GestureDetector(
            onTap: () => context.push('/subscriptions'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: const SizedBox(height: 44, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          );
        }
        return GestureDetector(
          onTap: () => context.push('/subscriptions'),
          child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Storage unavailable', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                onPressed: () => ref.read(storageQuotaProvider.notifier).load(),
              ),
            ],
          ),
          ),
        );
      }
      final percent = q.usagePercentage.clamp(0, 100) / 100.0;
      final isFull = q.usagePercentage >= 90;
      return GestureDetector(
        onTap: () => context.push('/subscriptions'),
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: isFull ? AppColors.error.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFull ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.storage_rounded, color: isFull ? AppColors.error : AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Storage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                        child: Text(q.planName, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Text('${q.usagePercentage}%', style: TextStyle(color: isFull ? AppColors.error : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: percent, minHeight: 8, backgroundColor: AppColors.background, valueColor: AlwaysStoppedAnimation(isFull ? AppColors.error : AppColors.primary)),
                  ),
                  const SizedBox(height: 4),
                  Text('${q.formattedUsed} of ${q.formattedAllocated} used', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        ),
      );
    }
    if (q == null) {
      if (state.isLoading) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      return const SizedBox.shrink();
    }
    final percent = q.usagePercentage.clamp(0, 100) / 100.0;
    final isFull = q.usagePercentage >= 90;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: isFull ? AppColors.error.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isFull ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.storage_rounded, color: isFull ? AppColors.error : AppColors.primary, size: 18)),
              const SizedBox(width: 10),
              const Text('Storage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(q.planName, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: percent, minHeight: 10, backgroundColor: AppColors.background, valueColor: AlwaysStoppedAnimation(isFull ? AppColors.error : AppColors.primary)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${q.formattedUsed} of ${q.formattedAllocated} used', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('${q.usagePercentage}%', style: TextStyle(color: isFull ? AppColors.error : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${q.formattedRemaining} remaining', style: TextStyle(color: isFull ? AppColors.error : AppColors.textLight, fontSize: 11)),
          if (q.usagePercentage >= 80) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/subscriptions'),
                icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                label: Text(q.usagePercentage >= 100 ? 'Storage Full — Upgrade' : 'Upgrade for more storage'),
                style: ElevatedButton.styleFrom(backgroundColor: isFull ? AppColors.error : AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
