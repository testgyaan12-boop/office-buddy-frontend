import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../companies/companies_provider.dart';
import '../subscription/invoice_save_stub.dart'
    if (dart.library.js_interop) '../subscription/invoice_save_web.dart';

class JobSwitchState {
  final bool isLoading;
  final bool isGenerating;
  final bool isDownloading;
  final String? error;
  final String? downloadUrl;
  final String? packId;
  final String? status;
  final Map<String, int> selectedCounts;
  final List<Map<String, dynamic>> downloadDetails;

  const JobSwitchState({
    this.isLoading = false,
    this.isGenerating = false,
    this.isDownloading = false,
    this.error,
    this.downloadUrl,
    this.packId,
    this.status,
    this.selectedCounts = const {
      'OFFER_LETTER': 5,
      'JOINING_LETTER': 5,
      'INCREMENT_LETTER': 5,
      'PAYSLIP': 3,
      'CERTIFICATE': 5,
      'RELIEVING_LETTER': 5,
      'TDS_CERTIFICATE': 5,
      'CONFIRMATION_LETTER': 5,
    },
    this.downloadDetails = const [],
  });

  JobSwitchState copyWith({
    bool? isLoading,
    bool? isGenerating,
    bool? isDownloading,
    String? error,
    String? downloadUrl,
    String? packId,
    String? status,
    Map<String, int>? selectedCounts,
    List<Map<String, dynamic>>? downloadDetails,
  }) {
    return JobSwitchState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isDownloading: isDownloading ?? this.isDownloading,
      error: error,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      packId: packId ?? this.packId,
      status: status ?? this.status,
      selectedCounts: selectedCounts ?? this.selectedCounts,
      downloadDetails: downloadDetails ?? this.downloadDetails,
    );
  }
}

class JobSwitchNotifier extends StateNotifier<JobSwitchState> {
  final ApiClient _apiClient;

  JobSwitchNotifier(this._apiClient) : super(const JobSwitchState());

  void toggleFolder(String type, bool enabled) {
    final m = Map<String, int>.from(state.selectedCounts);
    if (enabled) {
      m[type] = type == 'PAYSLIP' ? 3 : 5;
      if (type == 'EXPERIENCE') {
        m['CERTIFICATE'] = 5;
        m['RELIEVING_LETTER'] = 5;
        m['TDS_CERTIFICATE'] = 5;
        m.remove('EXPERIENCE');
      }
      if (type == 'OFFER_LETTER') {
        m['CONFIRMATION_LETTER'] = 5;
      }
    } else {
      m[type] = 0;
      if (type == 'EXPERIENCE') {
        m['CERTIFICATE'] = 0;
        m['RELIEVING_LETTER'] = 0;
        m['TDS_CERTIFICATE'] = 0;
      }
      if (type == 'OFFER_LETTER') {
        m['CONFIRMATION_LETTER'] = 0;
      }
    }
    state = state.copyWith(selectedCounts: m);
  }

  void setCount(String type, int count) {
    final m = Map<String, int>.from(state.selectedCounts);
    m[type] = count.clamp(0, 20);
    if (type == 'EXPERIENCE') {
      m['CERTIFICATE'] = count.clamp(0, 20);
      m['RELIEVING_LETTER'] = count.clamp(0, 20);
      m['TDS_CERTIFICATE'] = count.clamp(0, 20);
    }
    if (type == 'OFFER_LETTER') {
      m['CONFIRMATION_LETTER'] = count.clamp(0, 20);
    }
    state = state.copyWith(selectedCounts: m);
  }

  Future<void> generateDefaultPack() async {
    state = state.copyWith(isGenerating: true, error: null, status: 'Generating...');
    try {
      final response = await _apiClient.post(ApiEndpoints.jobSwitchGenerate);
      state = JobSwitchState(
        isGenerating: false,
        downloadUrl: response.data['downloadUrl'] as String?,
        packId: response.data['id'] as String?,
        status: 'Ready',
        selectedCounts: state.selectedCounts,
        downloadDetails: state.downloadDetails,
      );
      await fetchDownloadDetails();
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Failed to generate pack', status: 'Failed');
    }
  }

  Future<void> generatePack({List<String>? companyIds, String? fromDate, String? toDate}) async {
    final counts = state.selectedCounts;
    final hasAny = counts.values.any((v) => v > 0);
    if (!hasAny) {
      state = state.copyWith(error: 'Select at least one folder');
      return;
    }
    state = state.copyWith(isGenerating: true, error: null, status: 'Generating...');
    try {
      final includeCounts = <String, int>{};
      counts.forEach((k, v) {
        if (v > 0) includeCounts[k] = v;
      });
      final data = <String, dynamic>{'includeCounts': includeCounts};
      if (companyIds != null && companyIds.isNotEmpty) data['companyIds'] = companyIds;
      if (fromDate != null) data['fromDate'] = fromDate;
      if (toDate != null) data['toDate'] = toDate;
      final response = await _apiClient.post(
        ApiEndpoints.jobSwitchGenerate,
        data: data,
      );
      state = JobSwitchState(
        isGenerating: false,
        downloadUrl: response.data['downloadUrl'] as String?,
        packId: response.data['id'] as String?,
        status: 'Ready',
        selectedCounts: counts,
        downloadDetails: state.downloadDetails,
      );
      await fetchDownloadDetails();
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Failed to generate pack', status: 'Failed');
    }
  }

  Future<Uint8List?> fetchPackPdf(String packId) async {
    state = state.copyWith(isDownloading: true, error: null);
    try {
      final bytes = await _apiClient.downloadBytes(ApiEndpoints.jobSwitchPackPdf(packId));
      state = state.copyWith(isDownloading: false);
      await fetchDownloadDetails();
      return bytes;
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: _downloadError(e));
      return null;
    }
  }

  String _downloadError(Object e) {
    try {
      final d = (e as DioException).response?.data;
      if (d is Map && d['message'] is String && (d['message'] as String).isNotEmpty) {
        final m = d['message'] as String;
        if (m.contains('Free download limit')) return 'Free limit reached — upgrade to paid plan';
        return m;
      }
    } catch (_) {}
    return 'Download failed';
  }

  Future<void> fetchDownloadDetails() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.jobSwitchPackDownloadDetails);
      final list = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      state = state.copyWith(downloadDetails: list);
    } catch (_) {}
  }
}

final jobSwitchProvider = StateNotifierProvider<JobSwitchNotifier, JobSwitchState>((ref) {
  return JobSwitchNotifier(ref.read(apiClientProvider));
});

class CustomAd {
  final int id;
  final String title;
  final String productImgLink;
  final String productOpenLink;

  const CustomAd({
    required this.id,
    required this.title,
    required this.productImgLink,
    required this.productOpenLink,
  });

  factory CustomAd.fromJson(Map<String, dynamic> j) => CustomAd(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        productImgLink: j['productImgLink'] as String? ?? '',
        productOpenLink: j['productOpenLink'] as String? ?? '',
      );
}

final customAdsProvider = FutureProvider.autoDispose<List<CustomAd>>((ref) async {
  try {
    final r = await ref.read(apiClientProvider).get(ApiEndpoints.customAds);
    if (r.data is! List) return const [];
    return (r.data as List).map((e) => CustomAd.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return const [];
  }
});

class JobSwitchScreen extends ConsumerStatefulWidget {
  const JobSwitchScreen({super.key});

  @override
  ConsumerState<JobSwitchScreen> createState() => _JobSwitchScreenState();
}

class _JobSwitchScreenState extends ConsumerState<JobSwitchScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(jobSwitchProvider.notifier).fetchDownloadDetails());
  }

  Future<void> _downloadPack() async {
    final state = ref.read(jobSwitchProvider);
    final packId = state.packId;
    if (packId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Pack'),
        content: const Text('Download all documents as a single PDF file? This will be logged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Download')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      if (kIsWeb) {
        final bytes = await ref.read(jobSwitchProvider.notifier).fetchPackPdf(packId);
        if (bytes == null) throw Exception(ref.read(jobSwitchProvider).error ?? 'Download failed');
        await savePdfInBrowser(bytes, 'job-switch-pack.pdf');
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/job-switch-pack.pdf';
        await ref.read(apiClientProvider).downloadFile(ApiEndpoints.jobSwitchPackPdf(packId), filePath);
        await ref.read(jobSwitchProvider.notifier).fetchDownloadDetails();
        if (mounted) await OpenFilex.open(filePath);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded successfully')));
    } catch (e) {
      debugPrint('_downloadPack error: $e');
      if (mounted) {
        final msg = ref.read(jobSwitchProvider).error ?? 'Download failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          const Icon(Icons.swap_horiz, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          const Text('Job Switch Pack', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Bundle all your documents for a smooth job switch', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _showDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  void _showCustomPackPopup(BuildContext context) {
    final selectedCompanies = <String>{};
    DateTime? fromDate;
    DateTime? toDate;
    Future.microtask(() {
      try {
        ref.read(companiesProvider.notifier).loadCompanies();
      } catch (_) {}
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx3, setSheet) => Consumer(
        builder: (ctx2, ref2, _) {
          final selState = ref2.watch(jobSwitchProvider);
          final companies = ref2.watch(companiesProvider).companies;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Custom Pack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text('${selState.selectedCounts.values.where((v) => v > 0).length} folders • ${selState.selectedCounts.values.fold<int>(0, (a, b) => a + b)} files', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Choose konsa folder chahiye and kitna', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  _FolderSelector(folder: 'Experience Certificates', types: const ['CERTIFICATE', 'RELIEVING_LETTER', 'TDS_CERTIFICATE'], icon: Icons.verified),
                  _FolderSelector(folder: 'Payslips', types: const ['PAYSLIP'], icon: Icons.receipt_long),
                  _FolderSelector(folder: 'Joining Letters', types: const ['JOINING_LETTER'], icon: Icons.how_to_reg),
                  _FolderSelector(folder: 'Offer Letters', types: const ['OFFER_LETTER', 'CONFIRMATION_LETTER'], icon: Icons.card_membership),
                  _FolderSelector(folder: 'Increment Letters', types: const ['INCREMENT_LETTER'], icon: Icons.trending_up),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Companies', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text(
                        selectedCompanies.isEmpty ? '(all)' : '(${selectedCompanies.length} selected)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      if (selectedCompanies.isNotEmpty)
                        TextButton(
                          onPressed: () => setSheet(() => selectedCompanies.clear()),
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (companies.isEmpty)
                    const Text('No companies found — all companies will be included', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companies.map((c) {
                        final selected = selectedCompanies.contains(c.id);
                        return FilterChip(
                          selected: selected,
                          onSelected: (_) => setSheet(() {
                            if (selected) {
                              selectedCompanies.remove(c.id);
                            } else {
                              selectedCompanies.add(c.id);
                            }
                          }),
                          label: Text(c.name, style: const TextStyle(fontSize: 12)),
                          selectedColor: const Color(0xFF6366F1),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : const Color(0xFF6366F1),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  const Text('Date Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx3,
                              initialDate: fromDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setSheet(() => fromDate = picked);
                          },
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(fromDate == null ? 'From date' : _showDate(fromDate!), style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx3,
                              initialDate: toDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setSheet(() => toDate = picked);
                          },
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(toDate == null ? 'To date' : _showDate(toDate!), style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      if (fromDate != null || toDate != null)
                        IconButton(
                          onPressed: () => setSheet(() {
                            fromDate = null;
                            toDate = null;
                          }),
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.15))),
                    child: Row(children: [const Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)), const SizedBox(width: 8), Expanded(child: Text('Free: 3 downloads • Paid unlocks unlimited.', style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.60))))]),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selState.isGenerating
                          ? null
                          : () async {
                              await ref2.read(jobSwitchProvider.notifier).generatePack(
                                    companyIds: selectedCompanies.toList(),
                                    fromDate: fromDate != null ? _apiDate(fromDate!) : null,
                                    toDate: toDate != null ? _apiDate(toDate!) : null,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (selState.downloadUrl != null && context.mounted) {
                                // keep on main screen to show download button
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: selState.isGenerating
                          ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 12), Text('Generating...')])
                          : const Text('Generate Custom Pack & Download'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobSwitchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Switch Pack')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ref.watch(customAdsProvider).when(
              data: (ads) => ads.isEmpty ? _buildHeaderCard() : _AdCarousel(ads: ads),
              loading: () => _buildHeaderCard(),
              error: (_, __) => _buildHeaderCard(),
            ),
            const SizedBox(height: 24),
            const Text('This pack includes:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _IncludeItem(icon: Icons.verified, label: 'Experience Certificates'),
            _IncludeItem(icon: Icons.exit_to_app, label: 'Relieving Letters'),
            _IncludeItem(icon: Icons.how_to_reg, label: 'Joining Letters'),
            _IncludeItem(icon: Icons.card_membership, label: 'Offer Letters'),
            _IncludeItem(icon: Icons.trending_up, label: 'Increment Letters'),
            _IncludeItem(icon: Icons.receipt_long, label: 'Last 3 Months Payslips'),
            _IncludeItem(icon: Icons.receipt, label: 'TDS Certificates'),
            _IncludeItem(icon: Icons.task_alt, label: 'Confirmation Letters'),
            const SizedBox(height: 24),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isGenerating ? null : () => ref.read(jobSwitchProvider.notifier).generateDefaultPack(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: state.isGenerating
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))), SizedBox(width: 12), Text('Generating...')])
                    : const Text('Generate Pack'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.isGenerating ? null : () => _showCustomPackPopup(context),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Custom Pack'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            if (state.downloadUrl != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isDownloading ? null : _downloadPack,
                  icon: state.isDownloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(state.isDownloading ? 'Downloading...' : 'Download PDF'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
            const SizedBox(height: 28),
            // Download details table — job_switch_pack_download_details
            Row(
              children: [
                const Icon(Icons.table_chart, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text('Download Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(onPressed: () => ref.read(jobSwitchProvider.notifier).fetchDownloadDetails(), icon: const Icon(Icons.refresh, size: 16), label: const Text('Refresh')),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.06))),
              child: state.downloadDetails.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No downloads yet — generate & download to create rows', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          DataColumn(label: Text('Pack', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          DataColumn(label: Text('Count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          DataColumn(label: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          DataColumn(label: Text('DownloadedAt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          DataColumn(label: Text('CreatedAt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          DataColumn(label: Text('DeletedAt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        ],
                        rows: state.downloadDetails.map((r) {
                          return DataRow(cells: [
                            DataCell(Text(r['userId']?.toString().substring(0, 8) ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(r['packId']?.toString().substring(0, 8) ?? '-', style: const TextStyle(fontSize: 11))),
                            DataCell(Text('${r['downloadCount'] ?? 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                            DataCell(Icon(r['active'] == true ? Icons.check_circle : Icons.cancel, size: 16, color: r['active'] == true ? Colors.green : Colors.red)),
                            DataCell(Text((r['downloadedAt'] ?? r['createdAt'] ?? '-').toString().substring(0, 19), style: const TextStyle(fontSize: 10))),
                            DataCell(Text((r['createdAt'] ?? '-').toString().substring(0, 19), style: const TextStyle(fontSize: 10))),
                            DataCell(Text(r['deletedAt']?.toString().substring(0, 19) ?? '-', style: const TextStyle(fontSize: 10, color: Colors.red))),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            const Text('Table: job_switch_pack_download_details — row-wise, soft delete (active/deletedAt), paid feasibility ready (isPaid on packs).', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

class _FolderSelector extends ConsumerWidget {
  final String folder;
  final List<String> types;
  final IconData icon;
  const _FolderSelector({required this.folder, required this.types, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(jobSwitchProvider).selectedCounts;
    final isOn = types.any((t) => (counts[t] ?? 0) > 0);
    final currentCount = types.map((t) => counts[t] ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isOn ? const Color(0xFF6366F1).withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Checkbox(value: isOn, onChanged: (v) { for (final t in types) ref.read(jobSwitchProvider.notifier).toggleFolder(t, v ?? false); }, activeColor: const Color(0xFF6366F1)),
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (isOn ? const Color(0xFF6366F1) : Colors.grey).withValues(alpha: 0.10), shape: BoxShape.circle), child: Icon(icon, size: 16, color: isOn ? const Color(0xFF6366F1) : Colors.grey)),
            const SizedBox(width: 10),
            Expanded(child: Text(folder, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOn ? const Color(0xFF0F172A) : Colors.black54))),
            if (isOn) ...[
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20, color: Color(0xFF6366F1)), onPressed: currentCount <= 1 ? null : () { for (final t in types) ref.read(jobSwitchProvider.notifier).setCount(t, currentCount - 1); }),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                child: Text('$currentCount', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF6366F1))),
              ),
              IconButton(icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF6366F1)), onPressed: currentCount >= 20 ? null : () { for (final t in types) ref.read(jobSwitchProvider.notifier).setCount(t, currentCount + 1); }),
            ] else
              const Text('Off', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _AdCarousel extends StatefulWidget {
  final List<CustomAd> ads;

  const _AdCarousel({required this.ads});

  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    if (widget.ads.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_current + 1) % widget.ads.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openAd(CustomAd ad) async {
    if (ad.productOpenLink.isEmpty) return;
    final uri = Uri.tryParse(ad.productOpenLink);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.ads.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final ad = widget.ads[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _openAd(ad),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (ad.productImgLink.isNotEmpty)
                          Image.network(
                            ad.productImgLink,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackTile(ad),
                          )
                        else
                          _fallbackTile(ad),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ad.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.ads.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.ads.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _current == i ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _fallbackTile(CustomAd ad) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.accentGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_rounded, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ad.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncludeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IncludeItem({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
