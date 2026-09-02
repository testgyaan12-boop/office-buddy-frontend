import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import 'companies_provider.dart';
import 'models/company_model.dart';

const _indigo = Color(0xFF6366F1);

class CompaniesTab extends ConsumerStatefulWidget {
  const CompaniesTab({super.key});
  @override
  ConsumerState<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends ConsumerState<CompaniesTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<CompanyModel> _filtered(List<CompanyModel> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q) || c.role.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companiesProvider);
    if (state.isLoading) return const LoadingShimmer();
    if (state.error != null) {
      return ErrorState(
        message: state.error,
        onRetry: () => ref.read(companiesProvider.notifier).loadCompanies(),
      );
    }
    if (state.companies.isEmpty) {
      return EmptyState(
        icon: Icons.business,
        title: AppStrings.noCompanies,
        subtitle: 'Add your first company to start organizing documents',
        action: ElevatedButton.icon(
          onPressed: () => context.push('/companies/add'),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.addCompany),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      );
    }

    final filtered = _filtered(state.companies);

    return Stack(
      children: [
        const GlassMeshBackground(),
        RefreshIndicator(
          color: _indigo,
          onRefresh: () => ref.read(companiesProvider.notifier).loadCompanies(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // Glass search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search companies, roles...',
                        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35), fontSize: 13, fontWeight: FontWeight.w500),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.65), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.45))),
                          child: const Icon(Icons.search_rounded, color: _indigo, size: 16),
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.black45), onPressed: () { _searchController.clear(); setState(() => _query = ''); })
                            : null,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.62),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.40))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.40))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: _indigo, width: 1.2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      ),
                    ),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: GlassCard(
                      blur: 12, opacity: 0.62, borderRadius: BorderRadius.circular(14),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Text(_query.isNotEmpty ? 'No companies match "$_query"' : 'No companies', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ),
                  ),
                )
              else
                ...filtered.map((c) => _CompanyCard(company: c, onTap: () => context.push('/companies/${c.id}'))),
              const SizedBox(height: 8),
              const _CompanyBanner(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanyBanner extends StatelessWidget {
  const _CompanyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organize Your Career',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add all your past and current companies to organize documents better',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/companies/add'),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Company', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
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
                Container(
                  width: 4,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.capitalizedName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          company.role,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.calendar_today,
                              label: company.duration,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.description,
                              label: '${company.documentCount} docs',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: color != null ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
