import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/date_badge.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../documents/models/document_model.dart';

class SearchState {
  final bool isLoading;
  final String? error;
  final List<DocumentModel> results;
  final String query;

  const SearchState({
    this.isLoading = false,
    this.error,
    this.results = const [],
    this.query = '',
  });

  SearchState copyWith({
    bool? isLoading,
    String? error,
    List<DocumentModel>? results,
    String? query,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      results: results ?? this.results,
      query: query ?? this.query,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiClient _apiClient;

  SearchNotifier(this._apiClient) : super(const SearchState());

  Future<void> loadAllDocuments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(ApiEndpoints.documents);
      final results = (response.data as List)
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = SearchState(results: results);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load documents',
      );
    }
  }

  Future<void> search(String query, {String? type, String? year}) async {
    if (query.isEmpty && type == null && year == null) {
      state = state.copyWith(results: []);
      return;
    }
    state = state.copyWith(isLoading: true, query: query, error: null);
    try {
      final params = <String, dynamic>{};
      if (query.isNotEmpty) params['q'] = query;
      if (type != null) params['type'] = type;
      if (year != null) params['year'] = year;

      final response = await _apiClient.get(
        '/documents/search',
        queryParameters: params,
      );
      final results = (response.data as List)
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = SearchState(results: results, query: query);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Search failed',
      );
    }
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(apiClientProvider));
});

class _DocTypeFilter {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _DocTypeFilter(this.value, this.label, this.icon, this.color);
}

const List<_DocTypeFilter> _typeFilters = [
  _DocTypeFilter('', 'All', Icons.all_inclusive, AppColors.primary),
  _DocTypeFilter('OFFER_LETTER', 'Offer', Icons.card_membership, AppColors.success),
  _DocTypeFilter('JOINING_LETTER', 'Join', Icons.how_to_reg, Color(0xFF00ACC1)),
  _DocTypeFilter('INCREMENT_LETTER', 'Increment', Icons.trending_up, AppColors.primary),
  _DocTypeFilter('PAYSLIP', 'Payslip', Icons.receipt_long, AppColors.warning),
  _DocTypeFilter('CERTIFICATE', 'Cert', Icons.verified, AppColors.accent),
  _DocTypeFilter('RELIEVING_LETTER', 'Relieve', Icons.exit_to_app, Color(0xFFE17055)),
];

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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedType = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(searchProvider.notifier).loadAllDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    ref.read(searchProvider.notifier).search(
          _searchController.text.trim(),
          type: _selectedType.isNotEmpty ? _selectedType : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Smart Search'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, company...',
                filled: true,
                fillColor: AppColors.primary.withOpacity(0.05),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: AppColors.primary, size: 20),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(fontSize: 15),
              onSubmitted: (_) => _performSearch(),
              onChanged: (v) {
                setState(() {});
                _performSearch();
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _typeFilters
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _selectedType == t.value,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? t.value : '';
                          });
                          _performSearch();
                        },
                        avatar: Icon(t.icon, size: 14, color: _selectedType == t.value ? Colors.white : t.color),
                        label: Text(t.label, style: const TextStyle(fontSize: 12)),
                        selectedColor: t.color,
                        checkmarkColor: Colors.white,
                        backgroundColor: t.color.withOpacity(0.08),
                        labelStyle: TextStyle(
                          color: _selectedType == t.value ? Colors.white : t.color,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: _selectedType == t.value ? t.color : t.color.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: state.isLoading
                ? const LoadingShimmer()
                : state.results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchController.text.isEmpty && _selectedType.isEmpty
                                    ? Icons.search
                                    : Icons.search_off,
                                size: 48,
                                color: AppColors.primary.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty && _selectedType.isEmpty
                                  ? 'Search your documents'
                                  : 'No documents found',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: state.results.length,
                        itemBuilder: (context, index) {
                          final doc = state.results[index];
                          final docColor = _docColor(doc.type);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
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
                                      Container(width: 4, height: 76, color: docColor),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: docColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(_docIcon(doc.type), color: docColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                                                        color: AppColors.textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                                  const SizedBox(width: 4),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.business, size: 12, color: AppColors.textLight),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      doc.companyName ?? 'No company',
                                                      style: const TextStyle(
                                                        color: AppColors.textLight,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  DateBadge(doc.formattedDate, fontSize: 10),
                                                ],
                                              ),
                                            ],
                                          ),
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
                      ),
          ),
        ],
      ),
    );
  }
}
