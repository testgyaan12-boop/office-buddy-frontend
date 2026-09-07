import 'dart:convert';

class ReminderModel {
  final String id;
  final String title;
  final String? description;
  final String? jd;
  final String type; // lookup_code e.g. PROBATION_COMPLETION, BIRTHDAY
  final String category; // professional / personal
  final String? companyId;
  final String? companyName;
  final String? fileKey;
  final String? fileUrl;
  final String? fileName;
  final DateTime remindAt;
  final Duration notifyBefore;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final bool notified;

  ReminderModel({
    required this.id,
    required this.title,
    this.description,
    this.jd,
    required this.type,
    this.category = 'personal',
    this.companyId,
    this.companyName,
    this.fileKey,
    this.fileUrl,
    this.fileName,
    required this.remindAt,
    required this.notifyBefore,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.notified = false,
  });

  DateTime get notifyAt => remindAt.subtract(notifyBefore);

  String get notifyBeforeLabel {
    if (notifyBefore.inDays >= 7) return '${notifyBefore.inDays ~/ 7}w before';
    if (notifyBefore.inDays >= 1) return '${notifyBefore.inDays}d before';
    if (notifyBefore.inHours >= 1) return '${notifyBefore.inHours}h before';
    return '${notifyBefore.inMinutes}m before';
  }

  String get typeLabel {
    switch (type) {
      case 'interview': return 'Interview';
      case 'insurance': return 'Insurance';
      case 'jd': return 'JD';
      case 'expiry': return 'Expiry';
      case 'meeting': return 'Meeting';
      case 'PROBATION_COMPLETION': return 'Probation completion';
      case 'APPRAISAL_DISCUSSION': return 'Appraisal discussion';
      case 'NOTICE_PERIOD_END': return 'Notice period end';
      case 'CERTIFICATION_EXPIRY': return 'Certification expiry';
      case 'BIRTHDAY': return 'Birthday';
      case 'INSURANCE': return 'Insurance';
      case 'EMI': return 'EMI';
      case 'SIP': return 'SIP';
      case 'RENT': return 'Rent';
      case 'INSURANCE_EXPIRY': return 'Insurance expiry';
      default:
        // Generic: PROBATION_COMPLETION -> Probation Completion
        return type.split('_').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'jd': jd,
        'type': type,
        'category': category,
        'companyId': companyId,
        'companyName': companyName,
        'fileKey': fileKey,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'remindAt': remindAt.toIso8601String(),
        'notifyBeforeMinutes': notifyBefore.inMinutes,
        'createdAt': createdAt.toIso8601String(),
        'notified': notified,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        jd: json['jd'] as String?,
        type: json['type'] as String? ?? 'custom',
        category: (json['category'] as String? ?? 'personal').toLowerCase(),
        companyId: json['companyId'] as String?,
        companyName: json['companyName'] as String?,
        fileKey: json['fileKey'] as String?,
        fileUrl: json['fileUrl'] as String?,
        fileName: json['fileName'] as String?,
        remindAt: DateTime.parse(json['remindAt'] as String),
        notifyBefore: Duration(minutes: (json['notifyBeforeMinutes'] as num?)?.toInt() ?? 60),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
        createdBy: json['createdBy'] as String?,
        updatedBy: json['updatedBy'] as String?,
        notified: json['notified'] as bool? ?? false,
      );

  static String encodeList(List<ReminderModel> list) => jsonEncode(list.map((e) => e.toJson()).toList());
  static List<ReminderModel> decodeList(String raw) {
    try {
      final arr = jsonDecode(raw) as List;
      return arr.map((e) => ReminderModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  ReminderModel copyWith({
    String? title,
    String? description,
    String? jd,
    String? type,
    String? category,
    String? companyId,
    String? companyName,
    String? fileKey,
    String? fileUrl,
    String? fileName,
    DateTime? remindAt,
    Duration? notifyBefore,
  }) =>
      ReminderModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        jd: jd ?? this.jd,
        type: type ?? this.type,
        category: category ?? this.category,
        companyId: companyId ?? this.companyId,
        companyName: companyName ?? this.companyName,
        fileKey: fileKey ?? this.fileKey,
        fileUrl: fileUrl ?? this.fileUrl,
        fileName: fileName ?? this.fileName,
        remindAt: remindAt ?? this.remindAt,
        notifyBefore: notifyBefore ?? this.notifyBefore,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
        updatedBy: updatedBy,
        notified: notified,
      );
}
