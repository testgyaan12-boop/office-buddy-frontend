import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class DocumentTypeScreen extends StatelessWidget {
  const DocumentTypeScreen({super.key});

  static const List<_DocTypeItem> _types = [
    _DocTypeItem('Offer Letter', Icons.card_membership, AppColors.success),
    _DocTypeItem('Joining Letter', Icons.how_to_reg, AppColors.primary),
    _DocTypeItem('Increment Letter', Icons.trending_up, AppColors.secondary),
    _DocTypeItem('Payslip', Icons.receipt_long, AppColors.warning),
    _DocTypeItem('Experience Certificate', Icons.verified, AppColors.success),
    _DocTypeItem('Relieving Letter', Icons.exit_to_app, AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Type')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          return Material(
            elevation: 2,
            shadowColor: AppColors.cardShadow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => context.pop(type.name),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: type.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(type.icon, color: type.color, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      type.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocTypeItem {
  final String name;
  final IconData icon;
  final Color color;

  const _DocTypeItem(this.name, this.icon, this.color);
}
