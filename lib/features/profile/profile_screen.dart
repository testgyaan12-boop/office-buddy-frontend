import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 20),
          if (user?.skills != null && user!.skills!.isNotEmpty) ...[
            _SkillChips(skills: user.skills!),
            const SizedBox(height: 16),
          ],
          _PersonalDetailsSection(user: user),
          const SizedBox(height: 16),
          _ProfessionalSection(user: user),
          const SizedBox(height: 16),
          _IdentitySection(user: user),
          const SizedBox(height: 16),
          _ContactAddressSection(user: user),
          const SizedBox(height: 24),
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsSection(user: user),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.logout, color: AppColors.error, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text('Confirm Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasIdentityDocs(dynamic user) {
    return user?.uanNumber != null || user?.pfNumber != null;
  }

  bool _hasContactDocs(dynamic user) {
    return user?.address != null ||
        user?.emergencyContact != null ||
        user?.bankAccountNumber != null ||
        user?.ifscCode != null;
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({required this.user});

  void _showAvatarPopup(BuildContext context, String? avatarUrl, String initial) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16)],
                    ),
                    child: CircleAvatar(
                      radius: 110,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(initial, style: const TextStyle(color: AppColors.primary, fontSize: 64, fontWeight: FontWeight.bold))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user?.name ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = (user?.name != null && (user!.name as String).isNotEmpty) ? (user!.name as String)[0].toUpperCase() : 'U';
    final avatarUrl = user?.avatarUrl as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAvatarPopup(context, avatarUrl, initial),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (user?.headline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.headline!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _calculateAge(String? dobStr) {
  if (dobStr == null || dobStr.isEmpty) return null;
  DateTime? dob = DateTime.tryParse(dobStr);
  if (dob == null) {
    // Try dd-MM-yyyy or dd/MM/yyyy
    try {
      final parts = dobStr.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        // Assume dd-MM-yyyy
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          if (y < 100) return null;
          // Determine if first part is year (yyyy-MM-dd) or day
          if (parts[0].length == 4) {
            dob = DateTime(y, m, d);
          } else {
            dob = DateTime(y, m, d);
            // Actually for dd-MM-yyyy, y is last part
            dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      }
    } catch (_) {}
  }
  if (dob == null) return null;
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
  if (age < 0) return null;
  return '$age yrs';
}

class _PersonalDetailsSection extends StatelessWidget {
  final dynamic user;
  const _PersonalDetailsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF5C6BC0);
    final age = _calculateAge(user?.dateOfBirth as String?);
    final dobValue = user?.dateOfBirth != null ? (user!.dateOfBirth as String) : '—';
    // Try to format dob as dd-MM-yyyy if possible
    String displayDob = dobValue;
    if (user?.dateOfBirth != null) {
      try {
        final d = DateTime.parse(user!.dateOfBirth as String);
        displayDob = '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
      } catch (_) {}
    }

    Widget buildItem(IconData icon, String label, String value) {
      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: _InfoRow(item: _InfoItem(icon: icon, label: label, value: value), color: color),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: const Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person_outline, color: color, size: 18)),
                  const SizedBox(width: 10),
                  Text('Personal Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Row1: Name , Gender
                  Row(
                    children: [
                      Expanded(child: buildItem(Icons.person, 'Name', user?.name ?? '—')),
                      const SizedBox(width: 8),
                      Expanded(child: buildItem(Icons.wc, 'Gender', user?.gender ?? '—')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row2: Email only full width
                  buildItem(Icons.email, 'Email', user?.email ?? '—'),
                  const SizedBox(height: 8),
                  // Row3: DOB and Age
                  Row(
                    children: [
                      Expanded(child: buildItem(Icons.cake, 'DOB', displayDob)),
                      const SizedBox(width: 8),
                      Expanded(child: buildItem(Icons.timelapse, 'Age', age ?? '—')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row4: Blood and Phone
                  Row(
                    children: [
                      Expanded(child: buildItem(Icons.bloodtype, 'Blood Group', user?.bloodGroup ?? '—')),
                      const SizedBox(width: 8),
                      Expanded(child: buildItem(Icons.phone, 'Phone', user?.phone ?? '—')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionalSection extends StatelessWidget {
  final dynamic user;
  const _ProfessionalSection({required this.user});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF26A69A);
    Widget buildItem(IconData icon, String label, String value, {bool isUrl = false, bool copyable = false}) {
      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: _InfoRow(item: _InfoItem(icon: icon, label: label, value: value, isUrl: isUrl, copyable: copyable), color: color),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: const Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.business_center, color: color, size: 18)),
                  const SizedBox(width: 10),
                  Text('Professional', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Row1: Current Company only
                  buildItem(Icons.business, 'Current Company', user?.currentCompany ?? '—'),
                  const SizedBox(height: 8),
                  // Row2: Salary and Expected
                  Row(
                    children: [
                      Expanded(child: buildItem(Icons.monetization_on, 'Salary', user?.salary ?? '—')),
                      const SizedBox(width: 8),
                      Expanded(child: buildItem(Icons.trending_up, 'Expected', user?.expectedSalary ?? '—')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row3: LinkedIn only
                  buildItem(Icons.link, 'LinkedIn', user?.linkedInUrl ?? '—', isUrl: user?.linkedInUrl != null, copyable: user?.linkedInUrl != null),
                  const SizedBox(height: 8),
                  // Row4: Portfolio only
                  buildItem(Icons.web, 'Portfolio', user?.portfolioUrl ?? '—', isUrl: user?.portfolioUrl != null, copyable: user?.portfolioUrl != null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  final dynamic user;
  const _IdentitySection({required this.user});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFFA726);
    if (user?.uanNumber == null && user?.pfNumber == null) return const SizedBox.shrink();
    Widget buildItem(IconData icon, String label, String value) {
      final canCopy = value != '—' && value.isNotEmpty;
      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: _InfoRow(item: _InfoItem(icon: icon, label: label, value: value, copyable: canCopy), color: color),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: const Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.verified_user, color: color, size: 18)),
                  const SizedBox(width: 10),
                  Text('Identity Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Row1: UAN only full width
                  buildItem(Icons.savings, 'UAN', user?.uanNumber ?? '—'),
                  const SizedBox(height: 8),
                  // Row2: PF No. only full width
                  buildItem(Icons.numbers, 'PF No.', user?.pfNumber ?? '—'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAddressSection extends StatelessWidget {
  final dynamic user;
  const _ContactAddressSection({required this.user});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF7E57C2);
    Widget buildItem(IconData icon, String label, String value) {
      final canCopy = (label == 'Bank A/c' || label == 'IFSC') && value != '—' && value.isNotEmpty;
      return Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: _InfoRow(item: _InfoItem(icon: icon, label: label, value: value, copyable: canCopy), color: color),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: const Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.location_on, color: color, size: 18)),
                  const SizedBox(width: 10),
                  Text('Contact & Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Row1: Address only
                  buildItem(Icons.home, 'Address', user?.address ?? '—'),
                  const SizedBox(height: 8),
                  // Row2: Bank only
                  buildItem(Icons.account_balance, 'Bank A/c', user?.bankAccountNumber ?? '—'),
                  const SizedBox(height: 8),
                  // Row3: IFSC only
                  buildItem(Icons.code, 'IFSC', user?.ifscCode ?? '—'),
                  const SizedBox(height: 8),
                  // Row4: Contact (Emergency) only
                  buildItem(Icons.contact_emergency, 'Emergency Contact', user?.emergencyContact ?? '—'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChips extends StatelessWidget {
  final String skills;

  const _SkillChips({required this.skills});

  @override
  Widget build(BuildContext context) {
    final list = skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: list.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Text(
            s,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_InfoItem> items;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
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
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items
                        .map((item) => SizedBox(
                              width: w,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: color.withOpacity(0.08)),
                                ),
                                child: _InfoRow(item: item, color: color),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isUrl;
  final bool copyable;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isUrl = false,
    this.copyable = false,
  });
}

class _InfoRow extends StatelessWidget {
  final _InfoItem item;
  final Color color;

  const _InfoRow({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final canCopy = item.copyable && item.value != '—' && item.value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: item.isUrl ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: item.value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.label} copied'), duration: const Duration(seconds: 1), backgroundColor: color),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.copy_rounded, size: 14, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final dynamic user;

  const _SettingsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          _settingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1, indent: 56),
          _settingsTile(
            context,
            icon: Icons.lock,
            title: 'App Lock',
            subtitle: 'PIN & Biometric',
            onTap: () => context.push('/app-lock'),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}