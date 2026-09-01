import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/date_badge.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../auth/auth_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${authState.user?.name ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        child: dashboardState.isLoading
            ? const CardShimmer()
            : dashboardState.error != null
                ? ErrorState(
                    message: dashboardState.error,
                    onRetry: () =>
                        ref.read(dashboardProvider.notifier).loadDashboard(),
                  )
                : _buildContent(dashboardState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/documents/upload'),
        child: const Icon(Icons.upload_file),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/companies');
              break;
            case 2:
              context.push('/timeline');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Companies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DashboardState state) {
    final stats = state.stats ?? const DashboardStats();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Office Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.description,
                    value: '${stats.totalDocuments}',
                    label: 'Documents',
                  ),
                  _StatItem(
                    icon: Icons.business,
                    value: '${stats.totalCompanies}',
                    label: 'Companies',
                  ),
                  _StatItem(
                    icon: Icons.work_history,
                    value: '${stats.experienceYears}y',
                    label: 'Experience',
                  ),
                ],
              ),
            ],
          ),
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
            Expanded(
              child: _QuickActionCard(
                icon: Icons.business,
                label: 'Companies',
                color: AppColors.secondary,
                onTap: () => context.push('/companies'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.timeline,
                label: 'Timeline',
                color: AppColors.success,
                onTap: () => context.push('/timeline'),
              ),
            ),
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
            (doc) => AppCard(
              onTap: () => context.push('/documents/preview/${doc.id}'),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getDocColor(doc.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDocIcon(doc.type),
                      color: _getDocColor(doc.type),
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
                ],
              ),
            ),
          ),
      ],
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
