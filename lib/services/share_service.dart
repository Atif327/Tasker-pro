import 'dart:convert';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../database/database_helper.dart';

class ShareService {
  static String createShareableTaskText(Task task, List<SubTask> subtasks) {
    final buffer = StringBuffer();
    
    // Task title
    buffer.writeln('📋 ${task.title}');
    buffer.writeln();
    
    // Description
    if (task.description.isNotEmpty) {
      buffer.writeln(task.description);
      buffer.writeln();
    }
    
    // Due date
    buffer.writeln('📅 Due: ${_formatDate(task.dueDate)}');
    if (task.dueTime != null) {
      buffer.writeln('⏰ Time: ${_formatTime(task.dueTime!)}');
    }
    buffer.writeln();
    
    // Priority
    final priorityText = ['Low', 'Medium', 'High'][task.priority];
    buffer.writeln('🎯 Priority: $priorityText');
    
    // Category
    if (task.category != null && task.category!.isNotEmpty) {
      buffer.writeln('🏷️ Category: ${task.category}');
    }
    
    // Repeating
    if (task.isRepeating) {
      buffer.writeln('🔄 Repeating: ${task.repeatType ?? "Yes"}');
    }
    buffer.writeln();
    
    // Subtasks
    if (subtasks.isNotEmpty) {
      buffer.writeln('Subtasks:');
      for (var i = 0; i < subtasks.length; i++) {
        final checkbox = subtasks[i].isCompleted ? '☑' : '☐';
        buffer.writeln('$checkbox ${subtasks[i].title}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('---');
    buffer.writeln('Created with Flutter Tasker Pro');
    
    return buffer.toString();
  }

  static String createShareableTaskJson(Task task, List<SubTask> subtasks) {
    return jsonEncode({
      'task': task.toMap(),
      'subtasks': subtasks.map((st) => st.toMap()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'Flutter Tasker Pro',
    });
  }

  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
