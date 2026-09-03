import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/date_badge.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/main_shell.dart';
import '../documents/documents_provider.dart';
import '../documents/models/document_model.dart';
import '../todo/goal_provider.dart';
import '../todo/widgets/goal_tab.dart';
import 'dashboard_provider.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
      child: state.isLoading
          ? const CardShimmer()
          : state.error != null
              ? ErrorState(
                  message: state.error,
                  onRetry: () =>
                      ref.read(dashboardProvider.notifier).loadDashboard(),
                )
              : _DashboardContent(
                  state: state,
                  onGoToCompanies: () =>
                      ref.read(shellTabProvider.notifier).state = 1,
                  onGoToTimeline: () =>
                      ref.read(shellTabProvider.notifier).state = 2,
                  onDeleteDocument: (doc) =>
                      _confirmDeleteDoc(context, ref, doc),
                ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onGoToCompanies;
  final VoidCallback onGoToTimeline;
  final void Function(DocumentModel) onDeleteDocument;

  const _DashboardContent({
    required this.state,
    required this.onGoToCompanies,
    required this.onGoToTimeline,
    required this.onDeleteDocument,
  });

  @override
  Widget build(BuildContext context) {
    final stats = state.stats ?? const DashboardStats();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.business,
                value: '${stats.totalCompanies}',
                label: 'Companies',
                color: AppColors.secondary,
                onTap: () => context.push('/companies'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatItem(
                icon: Icons.work_history,
                value: '${stats.experienceYears}y',
                label: 'Experience',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatItem(
                icon: Icons.description,
                value: '${stats.totalDocuments}',
                label: 'Documents',
                color: AppColors.primary,
                onTap: () => context.push('/search'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatItem(
                icon: Icons.verified,
                value: '${stats.totalCertificates}',
                label: 'Certificates',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        Consumer(
          builder: (_, ref, __) {
            final goalState = ref.watch(goalProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Goals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/goals'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: goalState.dashboardGoals.isEmpty
                      ? _EmptyGoalsHint()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 4),
                          itemCount: goalState.dashboardGoals.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            if (i == goalState.dashboardGoals.length) {
                              return const AddGoalTab();
                            }
                            return GoalTab(goal: goalState.dashboardGoals[i]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.upload_file,
                label: 'Upload',
                color: AppColors.primary,
                onTap: () => context.push('/documents/upload'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.business,
                label: 'Companies',
                color: AppColors.secondary,
                onTap: onGoToCompanies,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.timeline,
                label: 'Timeline',
                color: AppColors.success,
                onTap: onGoToTimeline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.swap_horiz,
                label: 'Job Switch',
                color: AppColors.accent,
                onTap: () => context.push('/job-switch-pack'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/search'),
              child: const Text('View All'),
            ),
          ],
        ),
        if (state.recentDocuments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                AppStrings.noDocuments,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...state.recentDocuments.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                onTap: () => context.push('/documents/preview/${doc.id}'),
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _docColor(doc.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _docIcon(doc.type),
                        color: _docColor(doc.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc.companyName ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DateBadge(doc.formattedDate, icon: Icons.calendar_today),
                    const SizedBox(width: 4),
                    Consumer(
                      builder: (context, ref, _) {
                        final delId = ref.watch(documentsProvider).deletingId;
                        final isDel = delId == doc.id;
                        return isDel
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                onPressed: () => onDeleteDocument(doc),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _docColor(String type) {
    switch (type) {
      case 'OFFER_LETTER':
      case 'JOINING_LETTER':
        return AppColors.success;
      case 'PAYSLIP':
        return AppColors.warning;
      case 'INCREMENT_LETTER':
        return AppColors.primary;
      case 'CERTIFICATE':
      case 'RELIEVING_LETTER':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'OFFER_LETTER':
        return Icons.card_membership;
      case 'JOINING_LETTER':
        return Icons.how_to_reg;
      case 'PAYSLIP':
        return Icons.receipt_long;
      case 'INCREMENT_LETTER':
        return Icons.trending_up;
      case 'CERTIFICATE':
        return Icons.verified;
      case 'RELIEVING_LETTER':
        return Icons.exit_to_app;
      default:
        return Icons.description;
    }
  }
}

void _confirmDeleteDoc(BuildContext context, WidgetRef ref, DocumentModel doc) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Document'),
      content: Text('Delete "${doc.title}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(documentsProvider.notifier).deleteDocument(doc.id);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class _EmptyGoalsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/goals'),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              'Add your first goal',
              style: TextStyle(color: AppColors.primary.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
