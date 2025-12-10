class Task {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? dueTime;
  final bool isCompleted;
  final bool isRepeating;
  final String? repeatType; // 'daily', 'weekly', 'custom'
  final String? repeatDays; // JSON string of selected days [0-6] for weekly repeat
  final DateTime createdAt;
  final DateTime? completedAt;
  final int priority; // 0: low, 1: medium, 2: high
  final String? category;
  final String? attachments; // JSON string of file paths

  Task({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.isRepeating = false,
    this.repeatType,
    this.repeatDays,
    required this.createdAt,
    this.completedAt,
    this.priority = 0,
    this.category,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'dueTime': dueTime?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isRepeating': isRepeating ? 1 : 0,
      'repeatType': repeatType,
      'repeatDays': repeatDays,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
      'category': category,
      'attachments': attachments,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      dueTime: map['dueTime'] != null ? DateTime.parse(map['dueTime']) : null,
      isCompleted: map['isCompleted'] == 1,
      isRepeating: map['isRepeating'] == 1,
      repeatType: map['repeatType'],
      repeatDays: map['repeatDays'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      priority: map['priority'] ?? 0,
      category: map['category'],
      attachments: map['attachments'],
    );
  }

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? dueTime,
    bool? isCompleted,
    bool? isRepeating,
    String? repeatType,
    String? repeatDays,
    DateTime? createdAt,
    DateTime? completedAt,
    int? priority,
    String? category,
    String? attachments,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      attachments: attachments ?? this.attachments,
    );
  }
}
