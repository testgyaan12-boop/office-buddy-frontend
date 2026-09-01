class GoalModel {
  final String id;
  final String title;
  final String? description;
  final String targetDate;
  final String category;
  final String status;
  final int remainingDays;
  final String createdAt;

  GoalModel({
    required this.id,
    required this.title,
    this.description,
    required this.targetDate,
    required this.category,
    required this.status,
    required this.remainingDays,
    required this.createdAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        targetDate: json['targetDate'] as String,
        category: json['category'] as String,
        status: json['status'] as String,
        remainingDays: (json['remainingDays'] as num).toInt(),
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'targetDate': targetDate,
        'category': category,
        'status': status,
      };

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isOverdue => remainingDays <= 0 && isActive;
}
