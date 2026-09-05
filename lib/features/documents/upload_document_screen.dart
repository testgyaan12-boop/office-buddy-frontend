import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../companies/companies_provider.dart';
import '../dashboard/dashboard_provider.dart';
import 'documents_provider.dart';
import 'lookup_provider.dart';
import 'models/document_model.dart';
import 'models/lookup_model.dart';

class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  ConsumerState<UploadDocumentScreen> createState() =>
      _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String _selectedType = '';
  String? _selectedCompanyId;
  DateTime? _documentDate;
  final _tagsController = TextEditingController();
  bool _isUploading = false;

  final List<_DocTypeOption> _documentTypes = [
    _DocTypeOption('OFFER_LETTER', 'Offer Letter', Icons.card_membership, AppColors.success),
    _DocTypeOption('JOINING_LETTER', 'Joining Letter', Icons.how_to_reg, const Color(0xFF00ACC1)),
    _DocTypeOption('INCREMENT_LETTER', 'Increment Letter', Icons.trending_up, AppColors.primary),
    _DocTypeOption('PAYSLIP', 'Payslip', Icons.receipt_long, AppColors.warning),
    _DocTypeOption('CERTIFICATE', 'Certificate', Icons.verified, AppColors.accent),
    _DocTypeOption('RELIEVING_LETTER', 'Relieving Letter', Icons.exit_to_app, const Color(0xFFE17055)),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(companiesProvider.notifier).loadCompanies();
    });
  }

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _documentDate = picked);
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final request = DocumentUploadRequest(
      fileBytes: _selectedFileBytes!,
      fileName: _selectedFileName ?? 'document',
      type: _selectedType,
      companyId: _selectedCompanyId!,
      documentDate: _documentDate,
      tags: _tagsController.text.isNotEmpty
          ? _tagsController.text.split(',').map((e) => e.trim()).toList()
          : [],
    );

    final ok = await ref.read(documentsProvider.notifier).uploadDocument(request);

    setState(() => _isUploading = false);

    if (!mounted) return;

    if (ok) {
      ref.read(dashboardProvider.notifier).loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(documentsProvider).error ?? 'Upload failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesState = ref.watch(companiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedFileBytes != null
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.primary.withOpacity(0.25),
                        width: 2,
                      ),
                      color: _selectedFileBytes != null
                          ? AppColors.success.withOpacity(0.04)
                          : AppColors.primary.withOpacity(0.04),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: _selectedFileBytes != null
                                ? LinearGradient(
                                    colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_selectedFileBytes != null
                                        ? AppColors.success
                                        : AppColors.primary)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _selectedFileBytes != null ? Icons.check : Icons.upload_file,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _selectedFileName ?? 'Tap to select PDF or Image',
                          style: TextStyle(
                            color: _selectedFileBytes != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: _selectedFileBytes != null ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedFileName == null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Supports PDF, JPG, PNG',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_selectedFileBytes != null) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _selectedFileBytes = null;
                              _selectedFileName = null;
                            }),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Remove', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(icon: Icons.description, text: 'Document Type', color: AppColors.primary),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final lookupState = ref.watch(lookupProvider);
                    final lookups = lookupState.lookups;
                    if (lookupState.isLoading) {
                      return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                    }
                    if (lookupState.error != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: const Color(0xFFF44336).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(lookupState.error!, style: const TextStyle(color: Color(0xFFF44336), fontSize: 12))),
                                TextButton(onPressed: () => ref.read(lookupProvider.notifier).loadDocTypes(), child: const Text('Retry', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                          // Fallback to static while error shown
                          DropdownButtonFormField<String>(
                            value: _selectedType.isEmpty ? null : _selectedType,
                            decoration: InputDecoration(
                              hintText: 'Select document type',
                              filled: true,
                              fillColor: AppColors.primary.withOpacity(0.04),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Select document type' : null,
                            items: _documentTypes.map((t) => DropdownMenuItem(value: t.value, child: Row(children: [Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: t.color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Icon(t.icon, size: 18, color: t.color)), const SizedBox(width: 10), Text(t.label)]))).toList(),
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ],
                      );
                    }
                    if (lookups.isEmpty) {
                      return DropdownButtonFormField<String>(
                        value: _selectedType.isEmpty ? null : _selectedType,
                        decoration: InputDecoration(
                          hintText: 'Select document type',
                          filled: true,
                          fillColor: AppColors.primary.withOpacity(0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _documentTypes.map((t) => DropdownMenuItem(value: t.value, child: Row(children: [Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: t.color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Icon(t.icon, size: 18, color: t.color)), const SizedBox(width: 10), Text(t.label)]))).toList(),
                        validator: (v) => v == null || v.isEmpty ? 'Select document type' : null,
                        onChanged: (v) => setState(() => _selectedType = v!),
                      );
                    }
                    final selectedLookup = lookups.where((l) => l.lookupCode == _selectedType).firstOrNull;
                    return Autocomplete<LookupModel>(
                      displayStringForOption: (opt) => opt.shortName,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return lookups;
                        final q = textEditingValue.text.toLowerCase();
                        return lookups.where((l) => l.shortName.toLowerCase().contains(q) || l.longName?.toLowerCase().contains(q) == true || l.lookupCode.toLowerCase().contains(q));
                      },
                      initialValue: selectedLookup != null ? TextEditingValue(text: selectedLookup.shortName) : null,
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search document type',
                            filled: true,
                            fillColor: AppColors.primary.withOpacity(0.04),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
                            prefixIcon: selectedLookup != null
                                ? Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(color: selectedLookup.color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: Icon(selectedLookup.icon, size: 16, color: selectedLookup.color),
                                    ),
                                  )
                                : const Icon(Icons.search, color: AppColors.textLight),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                          validator: (v) => _selectedType.isEmpty ? 'Select document type' : null,
                        );
                      },
                      onSelected: (LookupModel sel) {
                        setState(() => _selectedType = sel.lookupCode);
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 40,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final opt = options.elementAt(index);
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(color: opt.color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: Icon(opt.icon, size: 16, color: opt.color),
                                    ),
                                    title: Text(opt.shortName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    subtitle: opt.longName != null ? Text(opt.longName!, style: const TextStyle(fontSize: 11, color: AppColors.textLight)) : null,
                                    onTap: () => onSelected(opt),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                _SectionHeader(icon: Icons.business, text: 'Company', color: AppColors.secondary),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  decoration: InputDecoration(
                    hintText: 'Select company',
                    filled: true,
                    fillColor: AppColors.primary.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  items: companiesState.companies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.business, size: 16, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Text(c.capitalizedName),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCompanyId = v),
                ),
                const SizedBox(height: 24),
                _SectionHeader(icon: Icons.calendar_month, text: 'Document Date', color: AppColors.accent),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textLight.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: _documentDate != null ? AppColors.accent : AppColors.textLight,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _documentDate != null
                              ? formatDate(_documentDate!)
                              : 'Select document date',
                          style: TextStyle(
                            color: _documentDate != null ? AppColors.textPrimary : AppColors.textLight,
                            fontSize: 15,
                            fontWeight: _documentDate != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (_documentDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _documentDate = null),
                            child: const Icon(Icons.close, size: 16, color: AppColors.textLight),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(icon: Icons.label_outline, text: 'Tags', color: AppColors.warning),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: 'HR, Salary, Promotion',
                    filled: true,
                    fillColor: AppColors.primary.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Upload Document',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DocTypeOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _DocTypeOption(this.value, this.label, this.icon, this.color);
}
