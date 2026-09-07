import 'dart:async';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../companies/companies_provider.dart';
import '../documents/lookup_provider.dart';
import 'models/reminder_model.dart';
import 'reminder_provider.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});
  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.alarm_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          const Text('Reminders'),
        ]),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2))),
              child: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [Tab(text: 'Professional'), Tab(text: 'Personal')],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ReminderTab(category: 'professional', onAdd: _showAdd),
                  _ReminderTab(category: 'personal', onAdd: _showAdd),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAdd, backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  void _showAdd({ReminderModel? reminder, String? category}) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_) => _ReminderFormSheet(initial: reminder, initialCategory: category ?? reminder?.category));
  }

  void _confirmDelete(ReminderModel r) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Reminder?'),
      content: Text('Delete "${r.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { ref.read(reminderProvider.notifier).deleteReminder(r.id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Delete')),
      ],
    ));
  }
}

class _ReminderTab extends ConsumerWidget {
  final String category;
  final void Function({ReminderModel? reminder, String? category}) onAdd;
  const _ReminderTab({super.key, required this.category, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderProvider);
    final filtered = state.reminders.where((r) => r.category == category).toList();
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Error: ${state.error}', style: const TextStyle(color: AppColors.error)), const SizedBox(height: 8), ElevatedButton(onPressed: () => ref.read(reminderProvider.notifier).load(), child: const Text('Retry'))]));
    }
    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(reminderProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            Center(child: Text('Total: ${state.reminders.length} | $category: ${filtered.length} (debug)', style: const TextStyle(color: AppColors.textLight, fontSize: 10))),
            const SizedBox(height: 10),
            Center(
              child: Column(children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle), child: Icon(category == 'professional' ? Icons.work : Icons.person, size: 48, color: AppColors.textLight)),
                const SizedBox(height: 16),
                Text(category == 'professional' ? 'No professional reminders' : 'No personal reminders', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                Text(category == 'professional' ? 'Probation, appraisal, notice period...' : 'Birthday, insurance, EMI, SIP, rent...', style: const TextStyle(color: AppColors.textLight, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: () => onAdd(category: category), icon: const Icon(Icons.add), label: const Text('Add Reminder'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () => ref.read(reminderProvider.notifier).load(), icon: const Icon(Icons.refresh, size: 16), label: const Text('Refresh')),
              ]),
            ),
            const SizedBox(height: 24),
            _ReminderBanner(onAdd: () => onAdd(category: category)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(reminderProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Total: ${state.reminders.length} | $category: ${filtered.length}', style: const TextStyle(color: AppColors.textLight, fontSize: 10), textAlign: TextAlign.center)),
          ...filtered.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReminderCard(
                  reminder: r,
                  onEdit: () => onAdd(reminder: r),
                  onDelete: () async {
                    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete?'), content: Text('Delete "${r.title}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white), child: const Text('Delete'))]));
                    if (ok == true) ref.read(reminderProvider.notifier).deleteReminder(r.id);
                  },
                ),
              )),
          const SizedBox(height: 12),
          _ReminderBanner(onAdd: () => onAdd(category: category)),
        ],
      ),
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  final VoidCallback onAdd;
  const _ReminderBanner({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.12))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.alarm_add_rounded, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Stay Ahead', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Interviews, JD, insurance expiry — get notified before time.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 14), label: const Text('Add Reminder', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary))),
        ])),
      ]),
    );
  }
}

class _ReminderCard extends StatefulWidget {
  final ReminderModel reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ReminderCard({required this.reminder, required this.onEdit, required this.onDelete});
  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  Timer? _timer;
  @override
  void initState() { super.initState(); _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {})); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Color _typeColor(String t) {
    switch (t) {
      case 'interview': return const Color(0xFF6366F1);
      case 'insurance': return const Color(0xFF14B8A6);
      case 'jd': return const Color(0xFF8B5CF6);
      case 'expiry': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  String _countdown() {
    final diff = widget.reminder.remindAt.difference(DateTime.now());
    if (diff.isNegative) return 'Due';
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    if (d > 0) return '${d}d ${h}h left';
    if (h > 0) return '${h}h ${m}m left';
    return '${m}m left';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    final color = _typeColor(r.type);
    final df = DateFormat('d-MMM-yyyy hh:mm a');
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(children: [
          Container(width: 4, height: 88, color: color),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(r.type == 'interview' ? Icons.work : r.type == 'insurance' ? Icons.health_and_safety : r.type == 'jd' ? Icons.description : Icons.alarm, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text(r.typeLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600))),
            ]),
            if (r.description != null && r.description!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(r.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            if (r.jd != null && r.jd!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text('JD: ${r.jd}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11))),
            if (r.companyName != null && r.companyName!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Row(children: [const Icon(Icons.business, size: 11, color: AppColors.textLight), const SizedBox(width: 3), Text(r.companyName!, style: const TextStyle(color: AppColors.textLight, fontSize: 11))])),
            if (r.fileName != null && r.fileName!.isNotEmpty) InkWell(
              onTap: () => _showReminderFileOptions(context, r),
              child: Padding(padding: const EdgeInsets.only(top: 2), child: Row(children: [const Icon(Icons.attach_file, size: 11, color: AppColors.primary), const SizedBox(width: 3), Expanded(child: Text(r.fileName!, style: const TextStyle(color: AppColors.primary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)), const Icon(Icons.open_in_new, size: 12, color: AppColors.textLight)])),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(_countdown(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))),
              const SizedBox(width: 6),
              const Icon(Icons.notifications_active, size: 11, color: AppColors.textLight),
              const SizedBox(width: 3),
              Text(r.notifyBeforeLabel, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              const Spacer(),
              Text(df.format(r.remindAt), style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
            ]),
          ]))),
          const SizedBox(width: 4),
          Column(children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onEdit,
                child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 6),
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onDelete,
                child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.delete_outline, size: 16, color: AppColors.error)),
              ),
            ),
          ]),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }
}

void _showReminderFileOptions(BuildContext context, ReminderModel r) {
  if (r.fileUrl == null || r.fileUrl!.isEmpty) return;
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.attach_file, color: AppColors.primary, size: 20)), const SizedBox(width: 12), Expanded(child: Text(r.fileName ?? 'Attachment', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis))]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _FileOptionButton(icon: Icons.visibility_outlined, label: 'Open', color: AppColors.primary, onTap: () { Navigator.pop(ctx); _showFilePreview(context, r); })),
          const SizedBox(width: 12),
          Expanded(child: _FileOptionButton(icon: Icons.download_outlined, label: 'Download', color: AppColors.success, onTap: () { Navigator.pop(ctx); if (r.fileUrl != null) launchUrl(Uri.parse(r.fileUrl!), mode: LaunchMode.externalApplication); })),
          const SizedBox(width: 12),
          Expanded(child: _FileOptionButton(icon: Icons.share_outlined, label: 'Share', color: AppColors.secondary, onTap: () { Navigator.pop(ctx); if (r.fileUrl != null) SharePlus.instance.share(ShareParams(text: '${r.title}\n${r.fileUrl}')); })),
        ]),
      ]),
    ),
  );
}

void _showFilePreview(BuildContext context, ReminderModel r) {
  final url = r.fileUrl ?? '';
  final isImage = url.toLowerCase().contains('.png') || url.toLowerCase().contains('.jpg') || url.toLowerCase().contains('.jpeg') || (r.fileName != null && (r.fileName!.toLowerCase().endsWith('.png') || r.fileName!.toLowerCase().endsWith('.jpg') || r.fileName!.toLowerCase().endsWith('.jpeg')));
  final isPdf = url.toLowerCase().contains('.pdf') || (r.fileName != null && r.fileName!.toLowerCase().endsWith('.pdf'));
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75, maxWidth: MediaQuery.of(context).size.width * 0.9),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), border: Border(bottom: BorderSide(color: AppColors.textLight.withValues(alpha: 0.15)))),
              child: Row(children: [Expanded(child: Text(r.fileName ?? r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx))]),
            ),
            Flexible(
              child: isImage
                  ? InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                        errorWidget: (_, __, ___) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.broken_image, size: 48, color: AppColors.textLight), const SizedBox(height: 8), Text('Failed to load image', style: TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 12), ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Open externally'))])),
                      ),
                    )
                  : isPdf
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(r.fileName ?? 'Document.pdf', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text('PDF preview not available in dialog.\nOpen externally to view.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Open PDF')),
                          ]),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.description, size: 64, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            Text(r.fileName ?? r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Open file')),
                          ]),
                        ),
            ),
          ]),
        ),
      ),
    ),
  );
}

class _FileOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FileOptionButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))), child: Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))])),
    );
  }
}

class _ReminderFormSheet extends ConsumerStatefulWidget {
  final ReminderModel? initial;
  final String? initialCategory;
  const _ReminderFormSheet({super.key, this.initial, this.initialCategory});
  @override
  ConsumerState<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<_ReminderFormSheet> {
  late TextEditingController _title, _desc, _jd;
  late String _category;
  late String _type;
  String? _selectedCompanyId;
  Uint8List? _pickedBytes;
  String? _pickedName;
  DateTime? _remindAt;
  late Duration _notifyBefore;

  final _notifyOptions = [
    {'label': '15 min before', 'duration': const Duration(minutes: 15)},
    {'label': '30 min before', 'duration': const Duration(minutes: 30)},
    {'label': '1 hour before', 'duration': const Duration(hours: 1)},
    {'label': '3 hours before', 'duration': const Duration(hours: 3)},
    {'label': '1 day before', 'duration': const Duration(days: 1)},
    {'label': '3 days before', 'duration': const Duration(days: 3)},
    {'label': '1 week before', 'duration': const Duration(days: 7)},
  ];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _desc = TextEditingController(text: widget.initial?.description ?? '');
    _jd = TextEditingController(text: widget.initial?.jd ?? '');
    _category = widget.initialCategory ?? widget.initial?.category ?? 'professional';
    _selectedCompanyId = widget.initial?.companyId;
    _pickedName = widget.initial?.fileName;
    _remindAt = widget.initial?.remindAt;
    _notifyBefore = widget.initial?.notifyBefore ?? const Duration(hours: 1);
    _type = widget.initial?.type ?? '';
    // Load lookups for both categories + companies for dropdown
    Future.microtask(() {
      ref.read(lookupProvider.notifier).loadByCode('REMINDER_PROFESSIONAL');
      ref.read(lookupProvider.notifier).loadByCode('REMINDER_PERSONAL');
      ref.read(companiesProvider.notifier).loadCompanies();
    });
    // Set default type after frame when lookups available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lookups = ref.read(lookupProvider).lookups;
      final professionalCodes = ['PROBATION_COMPLETION', 'APPRAISAL_DISCUSSION', 'NOTICE_PERIOD_END', 'CERTIFICATION_EXPIRY'];
      final personalCodes = ['BIRTHDAY', 'INSURANCE', 'EMI', 'SIP', 'RENT', 'INSURANCE_EXPIRY'];
      final allowed = _category == 'professional' ? professionalCodes : personalCodes;
      final available = lookups.where((l) => allowed.contains(l.lookupCode)).toList();
      if (_type.isEmpty && available.isNotEmpty) {
        setState(() => _type = available.first.lookupCode);
      } else if (_type.isEmpty) {
        setState(() => _type = allowed.first);
      }
    });
  }

  @override
  void dispose() { _title.dispose(); _desc.dispose(); _jd.dispose(); super.dispose(); }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: _remindAt ?? DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2035));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_remindAt ?? DateTime.now()));
    if (time == null) return;
    setState(() => _remindAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(widget.initial != null ? 'Edit Reminder' : 'Add Reminder', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => setState(() { _category = 'professional'; _type = ''; }), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _category == 'professional' ? AppColors.primary : AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: _category == 'professional' ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.work, size: 16, color: _category == 'professional' ? Colors.white : AppColors.textSecondary), const SizedBox(width: 6), Text('Professional', style: TextStyle(color: _category == 'professional' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))])))),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(onTap: () => setState(() { _category = 'personal'; _type = ''; }), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: _category == 'personal' ? AppColors.primary : AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: _category == 'personal' ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person, size: 16, color: _category == 'personal' ? Colors.white : AppColors.textSecondary), const SizedBox(width: 6), Text('Personal', style: TextStyle(color: _category == 'personal' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))])))),
          ]),
          const SizedBox(height: 12),
          const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Consumer(builder: (context, ref, _) {
            final lookups = ref.watch(lookupProvider).lookups;
            final professionalCodes = ['PROBATION_COMPLETION', 'APPRAISAL_DISCUSSION', 'NOTICE_PERIOD_END', 'CERTIFICATION_EXPIRY'];
            final personalCodes = ['BIRTHDAY', 'INSURANCE', 'EMI', 'SIP', 'RENT', 'INSURANCE_EXPIRY'];
            final allowed = _category == 'professional' ? professionalCodes : personalCodes;
            final filtered = lookups.where((l) => allowed.contains(l.lookupCode)).toList();
            // Build dropdown items from lookup or fallback
            final items = filtered.isNotEmpty
                ? filtered.map((l) => DropdownMenuItem<String>(value: l.lookupCode, child: Row(children: [Icon(l.icon, size: 16, color: l.color), const SizedBox(width: 8), Text(l.shortName, style: const TextStyle(fontSize: 13))]))).toList()
                : allowed.map((code) {
                    final label = code.split('_').map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
                    return DropdownMenuItem<String>(value: code, child: Text(label, style: const TextStyle(fontSize: 13)));
                  }).toList();
            // Auto-select first if empty
            if (_type.isEmpty && items.isNotEmpty) {
              final first = items.first.value!;
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && _type.isEmpty) setState(() => _type = first); });
            }
            return DropdownButtonFormField<String>(
              value: _type.isEmpty ? null : _type,
              decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
              hint: const Text('Select type'),
              items: items,
              onChanged: (v) => setState(() => _type = v!),
              validator: (v) => (v == null || v.isEmpty) ? 'Type is required' : null,
            );
          }),
          if (_category == 'professional') ...[
            const SizedBox(height: 12),
            Consumer(builder: (context, ref, _) {
              final companies = ref.watch(companiesProvider).companies;
              return DropdownButtonFormField<String>(
                value: _selectedCompanyId,
                decoration: const InputDecoration(labelText: 'Company (optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select company')),
                  ...companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _selectedCompanyId = v),
              );
            }),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final res = await FilePicker.platform.pickFiles(withData: true, type: FileType.any);
              if (res != null && res.files.single.bytes != null) {
                setState(() { _pickedBytes = res.files.single.bytes; _pickedName = res.files.single.name; });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                const Icon(Icons.attach_file, size: 18, color: AppColors.textLight),
                const SizedBox(width: 8),
                Expanded(child: Text(_pickedName ?? 'Attach file (optional)', style: TextStyle(color: _pickedName != null ? AppColors.textPrimary : AppColors.textLight, fontSize: 13), overflow: TextOverflow.ellipsis)),
                if (_pickedName != null) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() { _pickedBytes = null; _pickedName = null; })),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _jd, maxLines: 2, decoration: const InputDecoration(labelText: 'JD / Notes', hintText: 'Job description, policy no, etc', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _pickDateTime, icon: const Icon(Icons.calendar_today, size: 16), label: Text(_remindAt != null ? DateFormat('d-MMM-yyyy hh:mm a').format(_remindAt!) : 'Pick date & time *'))),
            if (_remindAt != null) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _remindAt = null)),
          ]),
          const SizedBox(height: 12),
          const Text('Notify before', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Duration>(
            value: _notifyBefore,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: _notifyOptions.map((o) => DropdownMenuItem(value: o['duration'] as Duration, child: Text(o['label'] as String, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _notifyBefore = v!),
          ),
          const SizedBox(height: 20),
          Consumer(builder: (context, ref, _) {
            final isSaving = ref.watch(reminderProvider).isLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (_title.text.trim().isEmpty || _remindAt == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and date required')));
                          return;
                        }
                        if (_type.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a type')));
                          return;
                        }
                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: Text(widget.initial != null ? 'Confirm Update' : 'Confirm Save'),
                            content: Text(widget.initial != null ? 'Update "${widget.initial!.title}"?' : 'Save "${ _title.text.trim()}" reminder?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: Text(widget.initial != null ? 'Update' : 'Save')),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        final notifier = ref.read(reminderProvider.notifier);
                        if (widget.initial != null) {
                          await notifier.updateReminder(widget.initial!.id, widget.initial!.copyWith(title: _title.text.trim(), description: _desc.text.trim().isEmpty ? null : _desc.text.trim(), jd: _jd.text.trim().isEmpty ? null : _jd.text.trim(), type: _type, category: _category, companyId: _selectedCompanyId, remindAt: _remindAt!, notifyBefore: _notifyBefore), fileBytes: _pickedBytes, fileName: _pickedName);
                        } else {
                          await notifier.addReminder(ReminderModel(id: DateTime.now().millisecondsSinceEpoch.toString(), title: _title.text.trim(), description: _desc.text.trim().isEmpty ? null : _desc.text.trim(), jd: _jd.text.trim().isEmpty ? null : _jd.text.trim(), type: _type, category: _category, companyId: _selectedCompanyId, remindAt: _remindAt!, notifyBefore: _notifyBefore, createdAt: DateTime.now()), fileBytes: _pickedBytes, fileName: _pickedName);
                        }
                        if (!context.mounted) return;
                        final err = ref.read(reminderProvider).error;
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
                          return;
                        }
                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.initial != null ? 'Reminder updated' : 'Reminder saved'), backgroundColor: AppColors.success));
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.initial != null ? 'Update' : 'Save'),
              ),
            );
          }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
