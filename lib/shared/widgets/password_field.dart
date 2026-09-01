import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const PasswordField({super.key, required this.controller, this.validator});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _password = widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasUppercase = _password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = _password.contains(RegExp(r'[a-z]'));
    final hasDigit = _password.contains(RegExp(r'\d'));
    final hasSpecial = _password.contains(RegExp(r'[@$!%*?&]'));
    final hasMinLength = _password.length >= 8;
    final checks = [hasMinLength, hasUppercase, hasLowercase, hasDigit, hasSpecial];
    final score = checks.where((c) => c).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          validator: widget.validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
            suffixIcon: IconButton(
              icon: Icon(
                _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textLight,
              ),
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
            hintText: 'Password',
            hintStyle: const TextStyle(color: AppColors.textLight),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
        if (_password.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 5,
              minHeight: 4,
              backgroundColor: AppColors.textLight.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_strengthColor(score)),
            ),
          ),
          const SizedBox(height: 8),
          _Requirement(label: 'At least 8 characters', met: hasMinLength),
          _Requirement(label: '1 uppercase letter', met: hasUppercase),
          _Requirement(label: '1 lowercase letter', met: hasLowercase),
          _Requirement(label: '1 number', met: hasDigit),
          _Requirement(label: '1 special character (@\$!%*?&)', met: hasSpecial),
        ],
      ],
    );
  }

  Color _strengthColor(int score) {
    if (score <= 2) return AppColors.error;
    if (score <= 3) return Colors.orange;
    if (score <= 4) return Colors.yellow.shade700;
    return AppColors.success;
  }
}

class _Requirement extends StatelessWidget {
  final String label;
  final bool met;

  const _Requirement({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? AppColors.success : AppColors.textLight,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.success : AppColors.textLight,
              decoration: met ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
