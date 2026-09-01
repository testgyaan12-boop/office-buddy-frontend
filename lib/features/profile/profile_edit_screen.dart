import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../auth/auth_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _headlineController;
  late TextEditingController _phoneController;
  late TextEditingController _currentCompanyController;
  late TextEditingController _salaryController;
  late TextEditingController _expectedSalaryController;
  late TextEditingController _skillsController;
  late TextEditingController _addressController;
  late TextEditingController _linkedInController;
  late TextEditingController _portfolioController;
  late TextEditingController _panController;
  late TextEditingController _aadhaarController;
  late TextEditingController _uanController;
  late TextEditingController _pfController;
  late TextEditingController _bankAccountController;
  late TextEditingController _ifscController;
  late TextEditingController _emergencyController;
  String? _gender;
  String? _bloodGroup;
  String? _dateOfBirth;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _headlineController = TextEditingController(text: user?.headline ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _currentCompanyController = TextEditingController(text: user?.currentCompany ?? '');
    _salaryController = TextEditingController(text: user?.salary ?? '');
    _expectedSalaryController = TextEditingController(text: user?.expectedSalary ?? '');
    _skillsController = TextEditingController(text: user?.skills ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _linkedInController = TextEditingController(text: user?.linkedInUrl ?? '');
    _portfolioController = TextEditingController(text: user?.portfolioUrl ?? '');
    _panController = TextEditingController(text: user?.panNumber ?? '');
    _aadhaarController = TextEditingController(text: user?.aadhaarNumber ?? '');
    _uanController = TextEditingController(text: user?.uanNumber ?? '');
    _pfController = TextEditingController(text: user?.pfNumber ?? '');
    _bankAccountController = TextEditingController(text: user?.bankAccountNumber ?? '');
    _ifscController = TextEditingController(text: user?.ifscCode ?? '');
    _emergencyController = TextEditingController(text: user?.emergencyContact ?? '');
    _gender = user?.gender;
    _bloodGroup = user?.bloodGroup;
    _dateOfBirth = user?.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _phoneController.dispose();
    _currentCompanyController.dispose();
    _salaryController.dispose();
    _expectedSalaryController.dispose();
    _skillsController.dispose();
    _addressController.dispose();
    _linkedInController.dispose();
    _portfolioController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _uanController.dispose();
    _pfController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedImageBytes = result.files.single.bytes;
        _pickedImageName = result.files.single.name;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dateOfBirth != null ? DateTime.tryParse(_dateOfBirth!) : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked.toIso8601String().split('T')[0]);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    if (_pickedImageBytes != null && _pickedImageName != null) {
      await ref.read(authProvider.notifier).uploadAvatar(
            _pickedImageBytes!,
            _pickedImageName!,
          );
    }
    await ref.read(authProvider.notifier).updateProfile(
          name: name,
          headline: _headlineController.text.trim().isEmpty ? null : _headlineController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          currentCompany: _currentCompanyController.text.trim().isEmpty ? null : _currentCompanyController.text.trim(),
          salary: _salaryController.text.trim().isEmpty ? null : _salaryController.text.trim(),
          expectedSalary: _expectedSalaryController.text.trim().isEmpty ? null : _expectedSalaryController.text.trim(),
          skills: _skillsController.text.trim().isEmpty ? null : _skillsController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          bloodGroup: _bloodGroup,
          linkedInUrl: _linkedInController.text.trim().isEmpty ? null : _linkedInController.text.trim(),
          portfolioUrl: _portfolioController.text.trim().isEmpty ? null : _portfolioController.text.trim(),
          panNumber: _panController.text.trim().isEmpty ? null : _panController.text.trim(),
          aadhaarNumber: _aadhaarController.text.trim().isEmpty ? null : _aadhaarController.text.trim(),
          uanNumber: _uanController.text.trim().isEmpty ? null : _uanController.text.trim(),
          pfNumber: _pfController.text.trim().isEmpty ? null : _pfController.text.trim(),
          bankAccountNumber: _bankAccountController.text.trim().isEmpty ? null : _bankAccountController.text.trim(),
          ifscCode: _ifscController.text.trim().isEmpty ? null : _ifscController.text.trim(),
          emergencyContact: _emergencyController.text.trim().isEmpty ? null : _emergencyController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayImage = _pickedImageBytes;
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;
    final initial = (user?.name ?? 'U')[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'OB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AvatarCard(
              displayImage: displayImage,
              user: user,
              initial: initial,
              onPick: _pickImage,
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline,
              color: const Color(0xFF5C6BC0),
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  required: true,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                _buildDivider(),
                _buildField(
                  initialValue: user?.email ?? '',
                  label: 'Email',
                  icon: Icons.email_outlined,
                  readOnly: true,
                ),
                _buildDivider(),
                _buildField(
                  controller: _headlineController,
                  label: 'Headline',
                  icon: Icons.work,
                  hint: 'e.g. Senior Flutter Developer',
                ),
                _buildDivider(),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: _buildField(
                            controller: TextEditingController(
                              text: _dateOfBirth != null && _dateOfBirth!.isNotEmpty
                                  ? formatDate(DateTime.parse(_dateOfBirth!))
                                  : '',
                            ),
                            label: 'Date of Birth',
                            icon: Icons.cake,
                            suffix: const Icon(Icons.calendar_today, size: 18, color: AppColors.textLight),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: _inputDecoration('Gender', Icons.wc),
                        items: ['Male', 'Female', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ],
                ),
                _buildDivider(),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                        hint: '+91 98765 43210',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _bloodGroup,
                        decoration: _inputDecoration('Blood Group', Icons.bloodtype),
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _bloodGroup = v),
                      ),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildField(
                  controller: _skillsController,
                  label: 'Skills',
                  icon: Icons.auto_awesome,
                  hint: 'Flutter, Java, SQL',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Professional',
              icon: Icons.business_center,
              color: const Color(0xFF26A69A),
              children: [
                _buildField(
                  controller: _currentCompanyController,
                  label: 'Current Company',
                  icon: Icons.business,
                ),
                _buildDivider(),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _salaryController,
                        label: 'Current Salary',
                        icon: Icons.monetization_on,
                        hint: '₹',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _expectedSalaryController,
                        label: 'Expected Salary',
                        icon: Icons.trending_up,
                        hint: '₹',
                      ),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildField(
                  controller: _linkedInController,
                  label: 'LinkedIn URL',
                  icon: Icons.link,
                ),
                _buildDivider(),
                _buildField(
                  controller: _portfolioController,
                  label: 'Portfolio URL',
                  icon: Icons.web,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Identity Documents',
              icon: Icons.verified_user,
              color: const Color(0xFFFFA726),
              children: [
                _buildField(
                  controller: _panController,
                  label: 'PAN Number',
                  icon: Icons.credit_card,
                ),
                _buildDivider(),
                _buildField(
                  controller: _aadhaarController,
                  label: 'Aadhaar Number',
                  icon: Icons.badge,
                ),
                _buildDivider(),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _uanController,
                        label: 'UAN (PF)',
                        icon: Icons.savings,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _pfController,
                        label: 'PF Number',
                        icon: Icons.numbers,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Contact & Address',
              icon: Icons.location_on,
              color: const Color(0xFF7E57C2),
              children: [
                _buildField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.home,
                  maxLines: 3,
                ),
                _buildDivider(),
                _buildField(
                  controller: _emergencyController,
                  label: 'Emergency Contact',
                  icon: Icons.contact_emergency,
                  hint: 'Name & Phone',
                ),
                _buildDivider(),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _bankAccountController,
                        label: 'Bank Account',
                        icon: Icons.account_balance,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _ifscController,
                        label: 'IFSC Code',
                        icon: Icons.code,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.save),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textLight),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }

  Widget _buildField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    bool required = false,
    Widget? suffix,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textLight),
        suffixIcon: suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        isDense: true,
      ),
      style: TextStyle(
        color: readOnly ? AppColors.textLight : AppColors.textPrimary,
      ),
      validator: validator,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 44);
  }
}

class _AvatarCard extends StatelessWidget {
  final Uint8List? displayImage;
  final dynamic user;
  final String initial;
  final VoidCallback onPick;

  const _AvatarCard({
    required this.displayImage,
    required this.user,
    required this.initial,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.06),
            AppColors.secondary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onPick,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: Colors.white,
                backgroundImage: displayImage != null
                    ? (kIsWeb
                        ? Image.memory(displayImage!).image
                        : MemoryImage(displayImage!))
                    : (hasAvatar
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null),
                child: displayImage == null && !hasAvatar
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Change Photo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                border: Border(
                  left: BorderSide(color: color, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}