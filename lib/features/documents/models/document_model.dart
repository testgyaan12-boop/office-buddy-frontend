import 'dart:typed_data';

import '../../../core/utils/date_formatter.dart';

class DocumentModel {
  final String id;
  final String title;
  final String type;
  final String? fileName;
  final String? companyId;
  final String? companyName;
  final String? fileUrl;
  final String? fileKey;
  final int fileSize;
  final String? mimeType;
  final DateTime? documentDate;
  final List<String> tags;
  final DateTime uploadedAt;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    this.fileName,
    this.companyId,
    this.companyName,
    this.fileUrl,
    this.fileKey,
    this.fileSize = 0,
    this.mimeType,
    this.documentDate,
    this.tags = const [],
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? json['fileName'] as String? ?? '',
        type: json['type'] as String? ?? json['documentType'] as String? ?? '',
        fileName: json['fileName'] as String?,
        companyId: json['companyId'] as String?,
        companyName: json['companyName'] as String?,
        fileUrl: json['fileUrl'] as String?,
        fileKey: json['fileKey'] as String?,
        fileSize: json['fileSize'] as int? ?? 0,
        mimeType: json['mimeType'] as String?,
        documentDate: json['documentDate'] != null ? DateTime.tryParse(json['documentDate'] as String) : null,
        tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.parse(json['uploadedAt'] as String)
            : DateTime.now(),
      );

  String get formattedDate => formatDate(uploadedAt);
  String get formattedUploadAt => formatDate(uploadedAt);
  String get formattedRecievedAt => documentDate != null ? formatDate(documentDate!) : '';
  bool get hasDocumentDate => documentDate != null;
  String get formattedMonthYear => formatMonthYear(uploadedAt);

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isPdf {
    if (mimeType != null && mimeType!.toLowerCase() == 'application/pdf') return true;
    final name = fileName ?? '';
    if (name.toLowerCase().endsWith('.pdf')) return true;
    final url = fileUrl ?? '';
    if (url.toLowerCase().contains('.pdf')) return true;
    return false;
  }

  bool get isImage {
    if (mimeType != null && mimeType!.toLowerCase().startsWith('image/')) return true;
    final lower = (fileName ?? '').toLowerCase();
    final urlLower = (fileUrl ?? '').toLowerCase();
    bool check(String s) =>
        s.endsWith('.jpg') ||
        s.endsWith('.jpeg') ||
        s.endsWith('.png') ||
        s.endsWith('.webp') ||
        s.endsWith('.heic') ||
        s.endsWith('.heif') ||
        s.endsWith('.gif') ||
        s.endsWith('.bmp') ||
        s.endsWith('.wbmp') ||
        s.endsWith('.tiff') ||
        s.endsWith('.tif');
    return check(lower) || check(urlLower);
  }
}

List<DocumentModel> parseDocumentList(dynamic responseData) {
  List<dynamic> items;
  if (responseData is List) {
    items = responseData;
  } else if (responseData is Map && responseData['content'] is List) {
    items = responseData['content'] as List<dynamic>;
  } else {
    items = [];
  }
  return items
      .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

class DocumentUploadRequest {
  final Uint8List fileBytes;
  final String fileName;
  final String type;
  final String companyId;
  final DateTime? documentDate;
  final List<String> tags;

  DocumentUploadRequest({
    required this.fileBytes,
    required this.fileName,
    required this.type,
    required this.companyId,
    this.documentDate,
    this.tags = const [],
  });

  Map<String, dynamic> toFormFields() => {
        'fileName': fileName,
        'type': type,
        'companyId': companyId,
        if (documentDate != null) 'documentDate': documentDate!.toIso8601String(),
        if (tags.isNotEmpty) 'tags': tags.join(','),
      };
}
