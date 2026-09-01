import 'package:flutter/material.dart';
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
          _InfoSection(
            title: 'Personal Details',
            icon: Icons.person_outline,
            color: const Color(0xFF5C6BC0),
            items: [
              _InfoItem(icon: Icons.person, label: 'Name', value: user?.name ?? ''),
              _InfoItem(icon: Icons.email, label: 'Email', value: user?.email ?? ''),
              if (user?.headline != null) _InfoItem(icon: Icons.work, label: 'Headline', value: user!.headline!),
              if (user?.dateOfBirth != null) _InfoItem(icon: Icons.cake, label: 'DOB', value: user!.dateOfBirth!),
              if (user?.gender != null) _InfoItem(icon: Icons.wc, label: 'Gender', value: user!.gender!),
              if (user?.bloodGroup != null) _InfoItem(icon: Icons.bloodtype, label: 'Blood Group', value: user!.bloodGroup!),
              if (user?.phone != null) _InfoItem(icon: Icons.phone, label: 'Phone', value: user!.phone!),
            ],
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Professional',
            icon: Icons.business_center,
            color: const Color(0xFF26A69A),
            items: [
              if (user?.currentCompany != null) _InfoItem(icon: Icons.business, label: 'Current Company', value: user!.currentCompany!),
              if (user?.salary != null) _InfoItem(icon: Icons.monetization_on, label: 'Salary', value: user!.salary!),
              if (user?.expectedSalary != null) _InfoItem(icon: Icons.trending_up, label: 'Expected', value: user!.expectedSalary!),
              if (user?.linkedInUrl != null) _InfoItem(icon: Icons.link, label: 'LinkedIn', value: user!.linkedInUrl!, isUrl: true),
              if (user?.portfolioUrl != null) _InfoItem(icon: Icons.web, label: 'Portfolio', value: user!.portfolioUrl!, isUrl: true),
            ],
          ),
          if (_hasIdentityDocs(user)) ...[
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Identity Documents',
              icon: Icons.verified_user,
              color: const Color(0xFFFFA726),
              items: [
                if (user?.panNumber != null) _InfoItem(icon: Icons.credit_card, label: 'PAN', value: user!.panNumber!),
                if (user?.aadhaarNumber != null) _InfoItem(icon: Icons.badge, label: 'Aadhaar', value: user!.aadhaarNumber!),
                if (user?.uanNumber != null) _InfoItem(icon: Icons.savings, label: 'UAN', value: user!.uanNumber!),
                if (user?.pfNumber != null) _InfoItem(icon: Icons.numbers, label: 'PF No.', value: user!.pfNumber!),
              ],
            ),
          ],
          if (_hasContactDocs(user)) ...[
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Contact & Address',
              icon: Icons.location_on,
              color: const Color(0xFF7E57C2),
              items: [
                if (user?.address != null) _InfoItem(icon: Icons.home, label: 'Address', value: user!.address!),
                if (user?.emergencyContact != null) _InfoItem(icon: Icons.contact_emergency, label: 'Emergency', value: user!.emergencyContact!),
                if (user?.bankAccountNumber != null) _InfoItem(icon: Icons.account_balance, label: 'Bank A/c', value: user!.bankAccountNumber!),
                if (user?.ifscCode != null) _InfoItem(icon: Icons.code, label: 'IFSC', value: user!.ifscCode!),
              ],
            ),
          ],
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
    return user?.panNumber != null ||
        user?.aadhaarNumber != null ||
        user?.uanNumber != null ||
        user?.pfNumber != null;
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

  @override
  Widget build(BuildContext context) {
    final initial = (user?.name ?? 'U')[0].toUpperCase();
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
          Container(
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
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
            ...items.map((item) => _InfoRow(item: item, color: color)).toList(),
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

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isUrl = false,
  });
}

class _InfoRow extends StatelessWidget {
  final _InfoItem item;
  final Color color;

  const _InfoRow({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
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