import '../../../core/utils/date_formatter.dart';

class CompanyModel {
  final String id;
  final String name;
  final String role;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final int documentCount;

  CompanyModel({
    required this.id,
    required this.name,
    required this.role,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.documentCount = 0,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : DateTime(2000),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        isCurrent: json['isCurrent'] as bool? ?? false,
        documentCount: json['documentCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isCurrent': isCurrent,
      };

  String get capitalizedName {
    if (name.isEmpty) return '';
    return name.split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String get duration {
    if (startDate == DateTime(2000) && isCurrent) return 'Present';
    final start = formatMonthYear(startDate);
    final end = isCurrent ? 'Present' : endDate != null ? formatMonthYear(endDate!) : 'Unknown';
    return '$start - $end';
  }

  String get displayDate {
    final DateTime effectiveEnd;
    if (isCurrent) {
      effectiveEnd = DateTime.now();
    } else if (endDate != null) {
      effectiveEnd = endDate!;
    } else {
      return '';
    }
    final months = effectiveEnd.difference(startDate).inDays ~/ 30;
    final years = months ~/ 12;
    final remMonths = months % 12;
    if (years > 0) return '${years}y ${remMonths}m';
    return '${remMonths}m';
  }
}
