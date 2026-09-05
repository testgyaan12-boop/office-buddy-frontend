import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../dashboard/dashboard_provider.dart';
import '../timeline/timeline_provider.dart';
import 'documents_provider.dart';
import 'models/document_model.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentPreviewScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentPreviewScreen> createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState
    extends ConsumerState<DocumentPreviewScreen> {
  DocumentModel? _document;
  bool _isLoading = true;
  String? _error;
  String? _localPdfPath;
  bool _pdfLoading = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final response = await ref.read(apiClientProvider).get(
            '${ApiEndpoints.documents}/${widget.documentId}',
          );
      final doc = DocumentModel.fromJson(response.data);
      setState(() {
        _document = doc;
        _isLoading = false;
      });
      if (doc.fileUrl != null && doc.isPdf) {
        _downloadPdf(doc.fileUrl!);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load document';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf(String url) async {
    setState(() => _pdfLoading = true);
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/preview_${widget.documentId}.pdf';
      await ref.read(apiClientProvider).downloadFile(url, filePath);
      setState(() {
        _localPdfPath = filePath;
        _pdfLoading = false;
      });
    } catch (_) {
      setState(() => _pdfLoading = false);
    }
  }

  String _extension(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf')) return '.pdf';
    if (lower.contains('.png')) return '.png';
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return '.jpg';
    if (lower.contains('.docx')) return '.docx';
    if (lower.contains('.doc')) return '.doc';
    if (lower.contains('.xlsx')) return '.xlsx';
    if (lower.contains('.xls')) return '.xls';
    return '';
  }

  void _shareDocument() {
    final title = _document?.title ?? 'Document';
    final url = _document?.fileUrl;
    if (url == null) return;
    SharePlus.instance.share(
      ShareParams(text: '$title\n\n$url'),
    );
  }

  void _confirmDownload() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Document'),
        content: Text(
            'Download "${_document?.title ?? 'this document'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _downloadFile();
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile() async {
    final url = _document?.fileUrl;
    if (url == null) return;

    setState(() => _isDownloading = true);
    try {
      if (kIsWeb) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      } else {
        final dir = await getTemporaryDirectory();
        final ext = _extension(url);
        final fileName = ext.isNotEmpty
            ? '${widget.documentId}$ext'
            : widget.documentId;
        final filePath = '${dir.path}/$fileName';
        await ref.read(apiClientProvider).downloadFile(url, filePath);
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
      debugPrint('_downloadFile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (ctx2, ref2, _) {
          final deletingId = ref2.watch(documentsProvider).deletingId;
          final isDeleting = deletingId == widget.documentId;
          return AlertDialog(
            title: const Text('Delete Document'),
            content: Text('Delete "${_document?.title ?? 'this document'}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        await ref.read(documentsProvider.notifier).deleteDocument(widget.documentId);
                        try {
                          await ref.read(dashboardProvider.notifier).loadDashboard();
                        } catch (_) {}
                        try {
                          await ref.read(timelineProvider.notifier).loadTimeline();
                        } catch (_) {}
                        if (ref.read(documentsProvider).error == null && ctx.mounted) {
                          Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted')));
                            context.pop();
                          }
                        } else if (ctx.mounted) {
                          Navigator.pop(ctx);
                          final err = ref.read(documentsProvider).error;
                          if (err != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_document?.title ?? 'Document Preview'),
        actions: [
          if (_document != null) ...[
            IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, color: AppColors.primary),
              onPressed: _isDownloading ? null : _confirmDownload,
              tooltip: 'Download',
            ),
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.primary),
              onPressed: () => _shareDocument(),
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _confirmDelete,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CardShimmer();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final doc = _document!;
    final url = doc.fileUrl;

    return Column(
      children: [
        Expanded(child: _buildPreview(doc, url)),
        _buildMetadata(doc),
      ],
    );
  }

  Widget _buildPreview(DocumentModel doc, String? url) {
    if (url == null) {
      return _fileIconPlaceholder(doc);
    }

    if (doc.isImage) {
      return InteractiveViewer(
        child: Center(
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (_, __, ___) => _fileIconPlaceholder(doc),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (doc.isPdf) {
      if (_pdfLoading) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading PDF...',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      }
      if (_localPdfPath != null) {
        return PDFView(
          filePath: _localPdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
        );
      }
      return _fileIconPlaceholder(doc);
    }

    return _fileIconPlaceholder(doc);
  }

  Widget _fileIconPlaceholder(DocumentModel doc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            doc.isPdf
                ? Icons.picture_as_pdf
                : Icons.description,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text('Preview not available',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMetadata(DocumentModel doc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                _metaChip(doc.type, Icons.category),
                const SizedBox(width: 8),
                if (doc.companyName != null)
                  _metaChip(doc.companyName!, Icons.business),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metaChip(doc.formattedDate, Icons.calendar_today),
                const SizedBox(width: 8),
                _metaChip(doc.formattedSize, Icons.storage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
