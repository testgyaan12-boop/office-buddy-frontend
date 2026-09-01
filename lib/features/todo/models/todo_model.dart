class TodoModel {
  final String id;
  final String? goalId;
  final String title;
  final String? content;
  final String type;
  final String? dueDate;
  final bool completed;
  final String createdAt;

  TodoModel({
    required this.id,
    this.goalId,
    required this.title,
    this.content,
    required this.type,
    this.dueDate,
    required this.completed,
    required this.createdAt,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
        id: json['id'] as String,
        goalId: json['goalId'] as String?,
        title: json['title'] as String,
        content: json['content'] as String?,
        type: json['type'] as String,
        dueDate: json['dueDate'] as String?,
        completed: json['completed'] as bool? ?? false,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'type': type,
        'dueDate': dueDate,
        'completed': completed,
      };

  bool get isTask => type == 'task';
  bool get isNote => type == 'note';
}
