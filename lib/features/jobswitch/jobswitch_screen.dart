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
  final String? error;
  final String? downloadUrl;
  final String? status;

  const JobSwitchState({
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.downloadUrl,
    this.status,
  });

  JobSwitchState copyWith({
    bool? isLoading,
    bool? isGenerating,
    String? error,
    String? downloadUrl,
    String? status,
  }) {
    return JobSwitchState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
    );
  }
}

class JobSwitchNotifier extends StateNotifier<JobSwitchState> {
  final ApiClient _apiClient;

  JobSwitchNotifier(this._apiClient) : super(const JobSwitchState());

  Future<void> generatePack() async {
    state = state.copyWith(isGenerating: true, error: null, status: 'Generating...');
    try {
      final response = await _apiClient.post('/job-switch/generate');
      state = JobSwitchState(
        isGenerating: false,
        downloadUrl: response.data['downloadUrl'] as String?,
        status: 'Ready',
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate pack',
        status: 'Failed',
      );
    }
  }
}

final jobSwitchProvider =
    StateNotifierProvider<JobSwitchNotifier, JobSwitchState>((ref) {
  return JobSwitchNotifier(ref.read(apiClientProvider));
});

class JobSwitchScreen extends ConsumerStatefulWidget {
  const JobSwitchScreen({super.key});

  @override
  ConsumerState<JobSwitchScreen> createState() => _JobSwitchScreenState();
}

class _JobSwitchScreenState extends ConsumerState<JobSwitchScreen> {
  bool _isDownloading = false;

  Future<void> _downloadPack() async {
    final state = ref.read(jobSwitchProvider);
    final url = state.downloadUrl;
    if (url == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Pack'),
        content: const Text('Download the Job Switch Pack ZIP file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDownloading = true);
    try {
      final fullUrl = url.startsWith('http')
          ? url
          : '${ApiEndpoints.baseUrl.replaceAll('/api/v1', '')}$url';
      if (kIsWeb) {
        await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.platformDefault);
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/job_switch_pack.zip';
        await ref.read(apiClientProvider).downloadFile(fullUrl, filePath);
        if (mounted) {
          await OpenFilex.open(filePath);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded successfully')),
        );
      }
    } catch (e) {
      debugPrint('_downloadPack error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.swap_horiz, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Job Switch Pack',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bundle all your documents for a smooth job switch',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'This pack includes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _IncludeItem(
              icon: Icons.verified,
              label: 'Experience Certificates',
            ),
            _IncludeItem(
              icon: Icons.exit_to_app,
              label: 'Relieving Letters',
            ),
            _IncludeItem(
              icon: Icons.how_to_reg,
              label: 'Joining Letters',
            ),
            _IncludeItem(
              icon: Icons.card_membership,
              label: 'Offer Letters',
            ),
            _IncludeItem(
              icon: Icons.trending_up,
              label: 'Increment Letters',
            ),
            _IncludeItem(
              icon: Icons.receipt_long,
              label: 'Last 3 Months Payslips',
            ),
            const SizedBox(height: 32),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isGenerating
                    ? null
                    : () => ref.read(jobSwitchProvider.notifier).generatePack(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating...'),
                        ],
                      )
                    : Text(state.downloadUrl != null
                        ? 'Download Pack'
                        : 'Generate Pack'),
              ),
            ),
            if (state.downloadUrl != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDownloading ? null : _downloadPack,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isDownloading ? 'Downloading...' : 'Download ZIP'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
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
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
