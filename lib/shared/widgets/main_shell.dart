import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/companies/companies_provider.dart';
import '../../features/dashboard/dashboard_provider.dart';
import '../../features/timeline/timeline_provider.dart';
import '../../features/todo/goal_provider.dart';
import '../../features/community/community_provider.dart';
import '../../features/dashboard/dashboard_tab.dart';
import '../../features/companies/companies_tab.dart';
import '../../features/timeline/timeline_tab.dart';
import '../../features/community/community_tab.dart';

final shellTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: _buildAppBar(currentIndex, authState),
      body: IndexedStack(
        index: currentIndex,
        children: const [
          DashboardTab(),
          CompaniesTab(),
          TimelineTab(),
          CommunityTab(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.dashboard,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: () => _onTabSelected(0),
              ),
              _navItem(
                icon: Icons.business,
                label: 'Companies',
                index: 1,
                currentIndex: currentIndex,
                onTap: () => _onTabSelected(1),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 26),
                    onPressed: () => context.push('/documents/upload'),
                  ),
                ),
              ),
              _navItem(
                icon: Icons.timeline,
                label: 'Timeline',
                index: 2,
                currentIndex: currentIndex,
                onTap: () => _onTabSelected(2),
              ),
              _navItem(
                icon: Icons.group,
                label: 'Community',
                index: 3,
                currentIndex: currentIndex,
                onTap: () => _onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    final current = ref.read(shellTabProvider);
    if (index == current) return;
    ref.read(shellTabProvider.notifier).state = index;
    switch (index) {
      case 0:
        ref.read(dashboardProvider.notifier).loadDashboard();
        ref.read(goalProvider.notifier).loadDashboardGoals();
        break;
      case 1:
        ref.read(companiesProvider.notifier).loadCompanies();
        break;
      case 2:
        ref.read(timelineProvider.notifier).loadTimeline();
        break;
      case 3:
        ref.read(communityProvider.notifier).loadCommunity();
        break;
    }
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final selected = currentIndex == index;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textLight, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textLight,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoTitle(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'OB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(int currentIndex, AuthState authState) {
    switch (currentIndex) {
      case 0:
        final userName = authState.user?.name ?? 'User';
        return AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Hi, $userName 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/search'),
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => context.push('/todos'),
            ),
            IconButton(
              icon: const Icon(Icons.smart_toy, color: AppColors.primary),
              onPressed: () {
                ref.read(shellTabProvider.notifier).state = 0;
                context.push('/ai');
              },
            ),
            if (authState.user?.avatarUrl != null &&
                authState.user!.avatarUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: () => context.push('/profile'),
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        CachedNetworkImageProvider(authState.user!.avatarUrl!),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.account_circle, size: 28),
                onPressed: () => context.push('/profile'),
              ),
          ],
        );
      case 1:
        return AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _logoTitle(AppStrings.companies),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => context.push('/companies/add'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      case 2:
        return AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _logoTitle('Career Timeline'),
          ),
        );
      case 3:
        return AppBar(
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: Colors.transparent,
        );
      default:
        return AppBar();
    }
  }

}
