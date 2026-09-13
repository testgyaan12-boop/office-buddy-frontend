class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? groupAvatar;
  final int memberCount;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.groupAvatar,
    this.memberCount = 0,
  });

  factory GroupModel.fromJson(Map<String, dynamic> j) => GroupModel(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    description: j['description'] as String?,
    groupAvatar: j['groupAvatar'] as String?,
    memberCount: j['memberCount'] as int? ?? 0,
  );
}

class GroupMemberModel {
  final String id;
  final String groupId;
  final String userId;
  final String status;
  final String? userName;
  final String? userEmail;

  GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.status,
    this.userName,
    this.userEmail,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> j) => GroupMemberModel(
    id: j['id'] as String,
    groupId: j['groupId'] as String,
    userId: j['userId'] as String,
    status: j['status'] as String? ?? 'PENDING',
    userName: j['userName'] as String?,
    userEmail: j['userEmail'] as String?,
  );
}

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String? content;
  final String type;
  final String? fileUrl;
  final String? createdAt;
  final String? senderName;

  GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.content,
    required this.type,
    this.fileUrl,
    this.createdAt,
    this.senderName,
  });

  factory GroupMessageModel.fromJson(Map<String, dynamic> j) => GroupMessageModel(
    id: j['id'] as String,
    groupId: j['groupId'] as String,
    senderId: j['senderId'] as String,
    content: j['content'] as String?,
    type: j['type'] as String? ?? 'TEXT',
    fileUrl: j['fileUrl'] as String?,
    createdAt: j['createdAt'] as String?,
    senderName: j['senderName'] as String?,
  );

  bool get isImage => type == 'IMAGE';
  bool get isFile => type == 'FILE';
  bool get isLink => type == 'LINK';
  String? get linkUrl => isLink ? (fileUrl ?? content) : null;
}
