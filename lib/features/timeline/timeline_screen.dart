import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/widgets/date_badge.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import 'models/timeline_event.dart';
import 'timeline_provider.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(timelineProvider.notifier).loadTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);
    final sortedEvents = List<TimelineEvent>.from(state.events)
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Career Timeline')),
      body: state.isLoading
          ? const LoadingShimmer()
          : state.error != null
              ? ErrorState(
                  message: state.error,
                  onRetry: () =>
                      ref.read(timelineProvider.notifier).loadTimeline(),
                )
              : state.events.isEmpty
                  ? const EmptyState(
                      icon: Icons.timeline,
                      title: 'No timeline events',
                      subtitle: 'Events from your companies will appear here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedEvents.length,
                      itemBuilder: (context, index) {
                        final event = sortedEvents[index];
                        final isLast = index == sortedEvents.length - 1;
                        return _TimelineTile(
                          event: event,
                          isLast: isLast,
                          isFirst: index == 0,
                        );
                      },
                    ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;
  final bool isFirst;

  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(event.icon, color: event.color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.textLight.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: event.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.type,
                          style: TextStyle(
                            color: event.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (event.companyName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.companyName!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (event.isDocumentEvent) ...[
                        if (event.hasDocumentDate)
                          DateBadge(
                            'RecievedAt ${event.formattedRecievedAt}',
                            icon: Icons.event,
                            color: AppColors.accent,
                            fontSize: 8,
                          ),
                        if (event.hasDocumentDate) const SizedBox(width: 4),
                        DateBadge(
                          'UploadAt ${event.formattedUploadAt}',
                          icon: Icons.cloud_upload,
                          fontSize: 8,
                        ),
                      ] else
                        DateBadge(
                          formatDate(event.eventDate),
                          color: event.color,
                          fontSize: 8,
                          icon: Icons.event,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
