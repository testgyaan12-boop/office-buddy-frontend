import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/documents/models/document_model.dart';

void showDocumentOptions(BuildContext context, WidgetRef ref, DocumentModel doc) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(doc.isPdf ? Icons.picture_as_pdf : Icons.description, color: AppColors.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(doc.type.replaceAll('_', ' '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _OptionButton(icon: Icons.visibility_outlined, label: 'Open', color: AppColors.primary, onTap: () { Navigator.pop(ctx); context.push('/documents/preview/${doc.id}'); })),
            const SizedBox(width: 12),
            Expanded(child: _OptionButton(icon: Icons.download_outlined, label: 'Download', color: AppColors.success, onTap: () { Navigator.pop(ctx); _downloadDoc(ctx, ref, doc); })),
            const SizedBox(width: 12),
            Expanded(child: _OptionButton(icon: Icons.share_outlined, label: 'Share', color: AppColors.secondary, onTap: () { Navigator.pop(ctx); _shareDoc(doc); })),
          ]),
        ],
      ),
    ),
  );
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))]),
      ),
    );
  }
}

Future<void> _downloadDoc(BuildContext context, WidgetRef ref, DocumentModel doc) async {
  final url = doc.fileUrl;
  if (url == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file url')));
    return;
  }
  try {
    if (kIsWeb) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      return;
    }
    final dir = await getTemporaryDirectory();
    final ext = _ext(url);
    final name = ext.isNotEmpty ? '${doc.id}$ext' : doc.id;
    final path = '${dir.path}/$name';
    await ref.read(apiClientProvider).downloadFile(url, path);
    await OpenFilex.open(path);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded')));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
  }
}

void _shareDoc(DocumentModel doc) {
  final url = doc.fileUrl;
  if (url == null) return;
  SharePlus.instance.share(ShareParams(text: '${doc.title}\n\n$url'));
}

String _ext(String url) {
  final l = url.toLowerCase();
  if (l.contains('.pdf')) return '.pdf';
  if (l.contains('.png')) return '.png';
  if (l.contains('.jpg') || l.contains('.jpeg')) return '.jpg';
  if (l.contains('.docx')) return '.docx';
  if (l.contains('.doc')) return '.doc';
  return '';
}
