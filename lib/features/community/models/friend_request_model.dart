class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? receiverId;
  final String? receiverName;
  final String? receiverAvatar;
  final String status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.receiverId,
    this.receiverName,
    this.receiverAvatar,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      receiverId: json['receiverId'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverAvatar: json['receiverAvatar'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
}
