import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import 'models/timeline_event.dart';
import 'timeline_provider.dart';

class TimelineTab extends ConsumerWidget {
  const TimelineTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);
    final sortedEvents = List<TimelineEvent>.from(state.events)
      ..sort((a, b) {
        final c = b.uploadedAt.compareTo(a.uploadedAt);
        if (c != 0) return c;
        return b.eventDate.compareTo(a.eventDate);
      });

    if (state.isLoading) return const LoadingShimmer();
    if (state.error != null) {
      return ErrorState(
        message: state.error,
        onRetry: () => ref.read(timelineProvider.notifier).loadTimeline(),
      );
    }

    final grouped = <int, List<TimelineEvent>>{};
    for (final e in sortedEvents) {
      final y = e.eventDate.year;
      grouped.putIfAbsent(y, () => []).add(e);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () => ref.read(timelineProvider.notifier).loadTimeline(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (years.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No timeline yet', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ...years.expand((year) {
              final events = grouped[year]!;
              final byCompany = <String, List<TimelineEvent>>{};
              for (final e in events) {
                final k = e.companyName ?? 'General';
                byCompany.putIfAbsent(k, () => []).add(e);
              }
              final entries = byCompany.entries.toList();
              return entries.asMap().entries.expand((mapEntry) {
                final idx = mapEntry.key;
                final entry = mapEntry.value;
                final docs = entry.value.length;
                final date = entry.value.first.eventDate;
                final isLastCompany = idx == entries.length - 1;
                final isLastOverall = year == years.last && isLastCompany;
                return [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 56,
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 3))],
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(child: Text('$year', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
                              ),
                              if (!isLastOverall)
                                Expanded(
                                  child: Container(
                                    width: 2.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.primary.withValues(alpha: 0.05)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!isLastOverall) const SizedBox(height: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/search'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 4)), BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  children: [
                                    Container(width: 5, height: 88, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.14), AppColors.primary.withValues(alpha: 0.06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                                      ),
                                      child: const Icon(Icons.business, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 5),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                                              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.description, size: 12, color: AppColors.primary), const SizedBox(width: 4), Text('$docs documents', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600))]),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
                                                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.event, size: 11, color: AppColors.textLight), const SizedBox(width: 4), Text(formatDate(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500))]),
                                              ),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                      child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              });
            }),
          const SizedBox(height: 8),
          const _TimelineBanner(),
        ],
      ),
    );
  }
}

class _TimelineBanner extends StatelessWidget {
  const _TimelineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.timeline, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Career Timeline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Every milestone — companies, documents, and key events in one place', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
