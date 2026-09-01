import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_shimmer.dart';
import 'companies_provider.dart';
import 'models/company_model.dart';

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(companiesProvider.notifier).loadCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.companies)),
      body: state.isLoading
          ? const LoadingShimmer()
          : state.error != null
              ? ErrorState(
                  message: state.error,
                  onRetry: () =>
                      ref.read(companiesProvider.notifier).loadCompanies(),
                )
              : state.companies.isEmpty
                  ? EmptyState(
                      icon: Icons.business,
                      title: AppStrings.noCompanies,
                      subtitle: 'Add your first company to start organizing documents',
                      action: ElevatedButton.icon(
                        onPressed: () => context.push('/companies/add'),
                        icon: const Icon(Icons.add),
                        label: const Text(AppStrings.addCompany),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(companiesProvider.notifier).loadCompanies(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.companies.length,
                        itemBuilder: (context, index) {
                          final company = state.companies[index];
                          return _CompanyCard(
                            company: company,
                            onTap: () =>
                                context.push('/companies/${company.id}'),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/companies/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final CompanyModel company;
  final VoidCallback onTap;

  const _CompanyCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.capitalizedName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company.role,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      company.duration,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.description,
                        size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '${company.documentCount} docs',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }
}
