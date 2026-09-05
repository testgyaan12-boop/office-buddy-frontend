import 'dart:convert';
import 'package:flutter/material.dart';

class LookupModel {
  final int lookupId;
  final String lookupCode;
  final String shortName;
  final String? longName;
  final int? parentLookupId;
  final int sortedOrder;
  final bool isActive;
  final bool isDeleted;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  LookupModel({
    required this.lookupId,
    required this.lookupCode,
    required this.shortName,
    this.longName,
    this.parentLookupId,
    required this.sortedOrder,
    required this.isActive,
    required this.isDeleted,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory LookupModel.fromJson(Map<String, dynamic> json) => LookupModel(
        lookupId: json['lookupid'] as int? ?? json['lookupId'] as int? ?? 0,
        lookupCode: json['lookup_code'] as String? ?? json['lookupCode'] as String? ?? '',
        shortName: json['short_name'] as String? ?? json['shortName'] as String? ?? '',
        longName: json['long_name'] as String? ?? json['longName'] as String?,
        parentLookupId: json['parent_lookup_id'] as int? ?? json['parentLookupId'] as int?,
        sortedOrder: json['sorted_order'] as int? ?? json['sortedOrder'] as int? ?? 0,
        isActive: json['is_active'] == true || json['is_active'] == 1 || json['isActive'] == true,
        isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1 || json['isDeleted'] == true,
        remarks: json['remarks'] as String?,
        createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
        updatedAt: json['updated_at'] as String? ?? json['updatedAt'] as String?,
      );

  Map<String, dynamic> get remarksMap {
    if (remarks == null || remarks!.isEmpty) return {};
    try {
      return jsonDecode(remarks!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String get iconName => remarksMap['icon'] as String? ?? 'description';
  String get colorHex => remarksMap['color'] as String? ?? '#FF6C63FF';

  Color get color {
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  IconData get icon {
    switch (iconName) {
      case 'card_membership':
        return Icons.card_membership;
      case 'how_to_reg':
        return Icons.how_to_reg;
      case 'trending_up':
        return Icons.trending_up;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'receipt':
        return Icons.receipt;
      case 'task_alt':
        return Icons.task_alt;
      case 'verified':
        return Icons.verified;
      case 'exit_to_app':
        return Icons.exit_to_app;
      case 'description':
        return Icons.description;
      default:
        return Icons.description;
    }
  }
}
