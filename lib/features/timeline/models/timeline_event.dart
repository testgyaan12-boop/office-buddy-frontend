import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? companyName;
  final DateTime eventDate;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.companyName,
    required this.eventDate,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        type: json['eventType'] as String? ?? json['type'] as String? ?? '',
        companyName: json['companyName'] as String?,
        eventDate: DateTime.parse(json['eventDate'] as String),
      );

  Color get color {
    switch (type) {
      case 'JOINING':
        return AppColors.success;
      case 'PROMOTION':
        return AppColors.primary;
      case 'EXIT':
        return AppColors.accent;
      case 'INCREMENT':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get icon {
    switch (type) {
      case 'JOINING':
        return Icons.login;
      case 'PROMOTION':
        return Icons.arrow_upward;
      case 'EXIT':
        return Icons.logout;
      case 'INCREMENT':
        return Icons.trending_up;
      default:
        return Icons.event;
    }
  }
}
