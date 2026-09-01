class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String type;
  final String? fileUrl;
  final DateTime createdAt;
  final bool read;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.type = 'TEXT',
    this.fileUrl,
    required this.createdAt,
    this.read = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String?,
      type: json['type'] as String? ?? 'TEXT',
      fileUrl: json['fileUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool? ?? false,
    );
  }

  bool get isMine => false;
  bool get isImage => type == 'IMAGE';
  bool get isFile => type == 'FILE';
}
