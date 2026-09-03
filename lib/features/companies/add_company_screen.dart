import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import 'companies_provider.dart';
import 'models/company_model.dart';

class AddCompanyScreen extends ConsumerStatefulWidget {
  final String? companyId;

  const AddCompanyScreen({super.key, this.companyId});

  @override
  ConsumerState<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends ConsumerState<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;

  bool get isEditing => widget.companyId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final companies = ref.read(companiesProvider).companies;
      final company = companies.where((c) => c.id == widget.companyId).firstOrNull;
      if (company != null) {
        _nameController.text = company.name;
        _roleController.text = company.role;
        _startDate = company.startDate;
        _endDate = company.endDate;
        _isCurrent = company.isCurrent;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start date'), backgroundColor: AppColors.error));
      return;
    }
    if (!_isCurrent && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select end date or check Currently working here'), backgroundColor: AppColors.error));
      return;
    }

    final company = CompanyModel(
      id: widget.companyId ?? '',
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      startDate: _startDate!,
      endDate: _isCurrent ? null : _endDate,
      isCurrent: _isCurrent,
    );

    if (isEditing) {
      await ref.read(companiesProvider.notifier).updateCompany(widget.companyId!, company);
    } else {
      await ref.read(companiesProvider.notifier).addCompany(company);
    }

    final err = ref.read(companiesProvider).error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
      return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(companiesProvider).isSaving;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Company' : 'Add Company'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
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
                      _SectionLabel(icon: Icons.business, text: 'Company Info'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Google',
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Company name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Senior Software Engineer',
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Role is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(icon: Icons.calendar_month, text: 'Tenure'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Start Date',
                              value: _startDate,
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: 'End Date',
                              value: _isCurrent ? null : _endDate,
                              onTap: _isCurrent ? null : () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isCurrent = !_isCurrent),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isCurrent
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isCurrent
                                      ? AppColors.primary
                                      : AppColors.textLight.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isCurrent
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 18,
                                    color: _isCurrent ? AppColors.primary : AppColors.textLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Currently working here',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _isCurrent ? AppColors.primary : AppColors.textSecondary,
                                      fontWeight: _isCurrent ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                            onPressed: isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text(
                                    isEditing ? 'Update Company' : 'Save Company',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
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

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  const _DateField({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              size: 16,
              color: value != null ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null
                    ? formatDate(value!)
                    : label,
                style: TextStyle(
                  color: value != null ? AppColors.textPrimary : AppColors.textLight,
                  fontSize: 14,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
