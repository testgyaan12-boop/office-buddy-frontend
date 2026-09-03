import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

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
      // Experience folder toggles both CERT + RELIEVING together — handled in UI via helper
      if (type == 'EXPERIENCE') {
        m['CERTIFICATE'] = 5;
        m['RELIEVING_LETTER'] = 5;
        m.remove('EXPERIENCE');
      }
    } else {
      m[type] = 0;
      if (type == 'EXPERIENCE') {
        m['CERTIFICATE'] = 0;
        m['RELIEVING_LETTER'] = 0;
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
    }
    state = state.copyWith(selectedCounts: m);
  }

  Future<void> generatePack() async {
    final counts = state.selectedCounts;
    final hasAny = counts.values.any((v) => v > 0);
    if (!hasAny) {
      state = state.copyWith(error: 'Select at least one folder');
      return;
    }
    state = state.copyWith(isGenerating: true, error: null, status: 'Generating...');
    try {
      // Convert to includeCounts map for backend (only >0)
      final includeCounts = <String, int>{};
      counts.forEach((k, v) {
        if (v > 0) includeCounts[k] = v;
      });
      final response = await _apiClient.post(
        ApiEndpoints.jobSwitchGenerate,
        data: {'includeCounts': includeCounts},
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

  Future<String?> recordDownload(String packId) async {
    state = state.copyWith(isDownloading: true);
    try {
      final res = await _apiClient.post('${ApiEndpoints.jobSwitchDownload}$packId');
      final url = res.data['downloadUrl'] as String?;
      state = state.copyWith(isDownloading: false);
      await fetchDownloadDetails();
      return url;
    } catch (e) {
      String msg = 'Download failed';
      if (e.toString().contains('Free download limit')) msg = 'Free limit reached — upgrade to paid plan';
      state = state.copyWith(isDownloading: false, error: msg);
      return null;
    }
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
    final url = state.downloadUrl;
    if (packId == null || url == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Pack'),
        content: const Text('Download the Job Switch Pack ZIP file? This will be logged.'),
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

    // Record download (row-wise) — creates job_switch_pack_download_details row
    final trackedUrl = await ref.read(jobSwitchProvider.notifier).recordDownload(packId);
    final effectiveUrl = trackedUrl ?? url;

    try {
      final fullUrl = effectiveUrl.startsWith('http') ? effectiveUrl : '${ApiEndpoints.baseUrl.replaceAll('/api/v1', '')}$effectiveUrl';
      if (kIsWeb) {
        await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.platformDefault);
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/job_switch_pack.zip';
        await ref.read(apiClientProvider).downloadFile(fullUrl, filePath);
        if (mounted) await OpenFilex.open(filePath);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded successfully')));
    } catch (e) {
      debugPrint('_downloadPack error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
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
            Container(
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
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Customize Pack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text('${state.selectedCounts.values.where((v) => v > 0).length} folders • ${state.selectedCounts.values.fold<int>(0, (a, b) => a + b)} files', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Select konsa folder chahiye and kitna (count)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _FolderSelector(
              folder: 'Experience Certificates',
              types: const ['CERTIFICATE', 'RELIEVING_LETTER'],
              icon: Icons.verified,
            ),
            _FolderSelector(folder: 'Payslips', types: const ['PAYSLIP'], icon: Icons.receipt_long),
            _FolderSelector(folder: 'Joining Letters', types: const ['JOINING_LETTER'], icon: Icons.how_to_reg),
            _FolderSelector(folder: 'Offer Letters', types: const ['OFFER_LETTER'], icon: Icons.card_membership),
            _FolderSelector(folder: 'Increment Letters', types: const ['INCREMENT_LETTER'], icon: Icons.trending_up),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.15))),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Free: 3 downloads • Paid unlocks unlimited. Table below tracks every download.', style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.60)))),
                ],
              ),
            ),
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
                onPressed: state.isGenerating ? null : () => ref.read(jobSwitchProvider.notifier).generatePack(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: state.isGenerating
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))), SizedBox(width: 12), Text('Generating...')])
                    : const Text('Generate Custom Pack'),
              ),
            ),
            if (state.downloadUrl != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isDownloading ? null : _downloadPack,
                  icon: state.isDownloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                  label: Text(state.isDownloading ? 'Downloading...' : 'Download ZIP (Logged)'),
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
