import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/widgets/date_badge.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../companies/companies_provider.dart';
import '../companies/models/company_model.dart';
import '../documents/documents_provider.dart';
import '../documents/models/document_model.dart';
import '../timeline/timeline_provider.dart';
import '../timeline/models/timeline_event.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref
          .read(documentsProvider.notifier)
          .loadDocuments(companyId: widget.companyId);
      _loadCompany();
    });
  }

  Future<void> _loadCompany() async {
    final c = await ref
        .read(companiesProvider.notifier)
        .getCompanyById(widget.companyId);
    if (mounted) setState(() => _company = c);
  }

  void _confirmDeleteCompany(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (ctx2, ref2, _) {
          final saving = ref2.watch(companiesProvider).isSaving;
          return AlertDialog(
            title: const Text('Delete Company'),
            content: Text(
              'Delete "${_company?.name ?? 'this company'}"? '
              'It will be hidden from your list.',
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        await ref.read(companiesProvider.notifier).deleteCompany(widget.companyId);
                        // Cascade: timeline events for this company are soft-deleted on backend
                        try { await ref.read(timelineProvider.notifier).loadTimeline(); } catch (_) {}
                        if (ref.read(companiesProvider).error == null && ctx.mounted) {
                          Navigator.pop(ctx);
                          if (mounted) context.pop();
                        } else if (ctx.mounted) {
                          Navigator.pop(ctx);
                          if (mounted) {
                            final err = ref.read(companiesProvider).error;
                            if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = _company;

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.capitalizedName ?? 'Company'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.secondary.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (company != null)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _confirmDeleteCompany(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push('/companies/${widget.companyId}/edit'),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Documents'),
            Tab(text: 'Timeline'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DocumentsTab(companyId: widget.companyId),
          _TimelineTab(companyId: widget.companyId),
          _InfoTab(company: company),
        ],
      ),
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  final String companyId;

  const _DocumentsTab({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(documentsProvider);

    if (docState.isLoading) return const LoadingShimmer();
    if (docState.documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 48, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text('No documents yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/documents/upload'),
              icon: const Icon(Icons.upload),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: docState.documents.length,
      itemBuilder: (context, index) {
        final doc = docState.documents[index];
        final docColor = _getDocColor(doc.type);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: GestureDetector(
            onTap: () => context.push('/documents/preview/${doc.id}'),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    Container(width: 4, height: 72, color: docColor),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: docColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getDocIcon(doc.type),
                        color: docColor,
                        size: 22,
                      ),
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
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: docColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  doc.type.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: docColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              DateBadge(doc.formattedDate, icon: Icons.calendar_today, fontSize: 10),
                              const Spacer(),
                              InkWell(
                                onTap: () =>
                                    _confirmDeleteDoc(context, ref, doc),
                                child: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getDocColor(String type) {
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

  IconData _getDocIcon(String type) {
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

class _TimelineTab extends ConsumerStatefulWidget {
  final String companyId;

  const _TimelineTab({required this.companyId});

  @override
  ConsumerState<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends ConsumerState<_TimelineTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(timelineProvider.notifier).loadTimeline(companyId: widget.companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);

    if (state.isLoading) return const LoadingShimmer();
    if (state.error != null) {
      return ErrorState(
        message: state.error,
        onRetry: () => ref
            .read(timelineProvider.notifier)
            .loadTimeline(companyId: widget.companyId),
      );
    }
    if (state.events.isEmpty) {
      return EmptyState(
        icon: Icons.timeline,
        title: 'No timeline events yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.events.length,
      itemBuilder: (context, index) {
        final event = state.events[index];
        final isLast = index == state.events.length - 1;
        return _buildTimelineTile(event, isLast);
      },
    );
  }

  Widget _buildTimelineTile(TimelineEvent event, bool isLast) {
    final color = event.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
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
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(event.icon, color: Colors.white, size: 20),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: color.withOpacity(0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      children: [
                        Container(width: 4, height: 80, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        event.type,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    DateBadge(
                                      formatMonthYear(event.eventDate),
                                      color: event.color,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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
                              ],
                            ),
                          ),
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
    );
  }
}

class _InfoTab extends StatelessWidget {
  final dynamic company;

  const _InfoTab({required this.company});

  @override
  Widget build(BuildContext context) {
    if (company == null) {
      return const Center(child: Text('Company not found'));
    }
    final c = company;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.08),
                AppColors.secondary.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                c.capitalizedName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                c.role,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (c.isCurrent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Current Company',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatsChip(
                    icon: Icons.calendar_month,
                    value: c.displayDate,
                    label: 'Tenure',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatsChip(
                    icon: Icons.description,
                    value: '${c.documentCount}',
                    label: 'Documents',
                    color: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _InfoRow(icon: Icons.business, label: 'Company', value: c.capitalizedName),
              const Divider(height: 20),
              _InfoRow(icon: Icons.person, label: 'Role', value: c.role),
              const Divider(height: 20),
              _InfoRow(icon: Icons.calendar_today, label: 'Start', value: formatDate(c.startDate)),
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.calendar_today,
                label: 'End',
                value: c.isCurrent ? 'Present' : formatDate(c.endDate!),
              ),
              const Divider(height: 20),
              _InfoRow(icon: Icons.timeline, label: 'Period', value: c.duration),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.upload,
                label: 'Upload',
                color: AppColors.primary,
                onTap: () => context.push('/documents/upload'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.edit,
                label: 'Edit',
                color: AppColors.secondary,
                onTap: () => context.push('/companies/${c.id}/edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.download,
                label: 'Export',
                color: AppColors.accent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatsChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
