class FriendModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? headline;
  final String? skills;
  final bool online;

  FriendModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.headline,
    this.skills,
    this.online = false,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      headline: json['headline'] as String?,
      skills: json['skills'] as String?,
      online: json['online'] as bool? ?? false,
    );
  }
}
