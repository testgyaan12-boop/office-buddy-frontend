import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';

class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? companyName;
  final DateTime eventDate;
  final DateTime? documentDate;
  final DateTime uploadedAt;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.companyName,
    required this.eventDate,
    this.documentDate,
    required this.uploadedAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String v) => DateTime.parse(v);
    DateTime? tryParseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v as String);
    }

    final eventDate = parseDate(json['eventDate'] as String);
    final docDate = tryParseDate(json['documentDate']);
    DateTime upAt = tryParseDate(json['uploadedAt']) ??
        tryParseDate(json['createdAt']) ??
        eventDate;
    return TimelineEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: json['eventType'] as String? ?? json['type'] as String? ?? '',
      companyName: json['companyName'] as String?,
      eventDate: eventDate,
      documentDate: docDate,
      uploadedAt: upAt,
    );
  }

  String get formattedRecievedAt {
    if (documentDate != null) return formatDate(documentDate!);
    // Fallback for old rows where documentDate column was null:
    // eventDate was saved as documentDate (or startDate) and uploadedAt as createdAt -> different days => treat eventDate as ReceivedAt
    if (isDocumentEvent && !_isSameDay(eventDate, uploadedAt)) return formatDate(eventDate);
    return '';
  }

  String get formattedUploadAt => formatDate(uploadedAt);
  bool get hasDocumentDate {
    if (documentDate != null) return true;
    if (isDocumentEvent && !_isSameDay(eventDate, uploadedAt)) return true;
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool get isDocumentEvent {
    const docTypes = {
      'DOCUMENT_UPLOADED',
      'OFFER_RECEIVED',
      'COMPANY_JOINED',
      'INCREMENT',
      'PAYSLIP',
      'CERTIFICATE',
      'RELIEVED',
      'CONFIRMED',
    };
    return docTypes.contains(type);
  }

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
