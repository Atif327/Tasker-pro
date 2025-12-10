class Comment {
  final int? id;
  final int taskId;
  final int userId;
  final String userName; // Store user name for display
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Comment({
    this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      taskId: map['taskId'],
      userId: map['userId'],
      userName: map['userName'],
      text: map['text'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Comment copyWith({
    int? id,
    int? taskId,
    int? userId,
    String? userName,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
