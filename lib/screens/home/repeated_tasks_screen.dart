import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../database/database_helper.dart';
import '../../models/task_model.dart';
import '../../models/subtask_model.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/notification_service.dart';
import '../tasks/add_edit_task_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/task_card.dart';
import '../../providers/theme_provider.dart';

class RepeatedTasksScreen extends StatefulWidget {
  const RepeatedTasksScreen({Key? key}) : super(key: key);

  @override
  State<RepeatedTasksScreen> createState() => _RepeatedTasksScreenState();
}

class _RepeatedTasksScreenState extends State<RepeatedTasksScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  final NotificationService _notificationService = NotificationService.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      final tasks = await _dbHelper.getRepeatingTasks(userId);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTask(Task task) async {
    // Check if delete protection is enabled
    final deleteProtectionEnabled = await _biometricService.isDeleteProtectionEnabled();
    
    if (deleteProtectionEnabled) {
      // Require authentication
      final authenticated = await _biometricService.authenticateForDelete(context);
      if (!authenticated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required to delete')),
        );
        return;
      }
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repeating Task'),
        content: const Text('Are you sure you want to delete this repeating task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteTask(task.id!);
      _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repeating task deleted')),
      );
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (!task.isCompleted) {
      // Marking task as complete
      if (task.repeatType == 'daily') {
        // For daily repeating tasks, extend the due date by 1 day
        final nextDueDate = task.dueDate.add(const Duration(days: 1));
        DateTime? nextDueTime;
        if (task.dueTime != null) {
          nextDueTime = DateTime(
            nextDueDate.year,
            nextDueDate.month,
            nextDueDate.day,
            task.dueTime!.hour,
            task.dueTime!.minute,
          );
        }

        // Create new daily task for next day with fresh subtasks
        final newTask = Task(
          userId: task.userId,
          title: task.title,
          description: task.description,
          dueDate: nextDueDate,
          dueTime: nextDueTime,
          isCompleted: false,
          isRepeating: task.isRepeating,
          repeatType: task.repeatType,
          repeatDays: task.repeatDays,
          createdAt: DateTime.now(),
          priority: task.priority,
          category: task.category,
          attachments: task.attachments,
        );
        final createdNext = await _dbHelper.createTask(newTask);

        final oldSubtasks = await _dbHelper.getSubTasks(task.id!);
        for (final st in oldSubtasks) {
          await _dbHelper.createSubTask(
            SubTask(
              taskId: createdNext.id!,
              title: st.title,
              isCompleted: false,
              createdAt: DateTime.now(),
            ),
          );
        }

        // Cancel notifications for old task and schedule for the new one
        if (task.id != null) {
          await _notificationService.cancelTaskNotifications(task.id!);
        }
        if (nextDueTime != null) {
          final baseId = (createdNext.id ?? 0) * 1000;
          await _notificationService.scheduleRepeatingTaskNotification(
            createdNext,
            notificationId: baseId + 3,
            titleOverride: '🔄 Recurring Task: ${createdNext.title}',
          );
          // Repeating reminder 5 minutes before
          final reminderTime = nextDueTime.subtract(const Duration(minutes: 5));
          await _notificationService.scheduleRepeatingTaskNotification(
            createdNext.copyWith(dueTime: reminderTime),
            notificationId: baseId + 1,
            titleOverride: '⏰ Reminder: ${createdNext.title}',
          );
        }

        // Mark the old task as completed so it appears in Completed tab
        final completedTask = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await _dbHelper.updateTask(completedTask);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task completed! Next due: ${nextDueDate.day}/${nextDueDate.month}/${nextDueDate.year}')),
          );
        }
      } else if (task.repeatType == 'weekly') {
        // Compute next occurrence based on repeatDays
        List<int> days = [];
        if (task.repeatDays != null && task.repeatDays!.isNotEmpty) {
          try {
            days = (jsonDecode(task.repeatDays!) as List).cast<int>();
          } catch (_) {}
        }
        final nextDueDate = _nextWeeklyDate(task.dueDate, days);
        DateTime? nextDueTime;
        if (task.dueTime != null) {
          nextDueTime = DateTime(
            nextDueDate.year,
            nextDueDate.month,
            nextDueDate.day,
            task.dueTime!.hour,
            task.dueTime!.minute,
          );
        }

        final newTask = Task(
          userId: task.userId,
          title: task.title,
          description: task.description,
          dueDate: nextDueDate,
          dueTime: nextDueTime,
          isCompleted: false,
          isRepeating: task.isRepeating,
          repeatType: task.repeatType,
          repeatDays: task.repeatDays,
          createdAt: DateTime.now(),
          priority: task.priority,
          category: task.category,
          attachments: task.attachments,
        );
        final createdNext = await _dbHelper.createTask(newTask);

        // Clone subtasks as unchecked
        final oldSubtasks = await _dbHelper.getSubTasks(task.id!);
        for (final st in oldSubtasks) {
          await _dbHelper.createSubTask(
            SubTask(
              taskId: createdNext.id!,
              title: st.title,
              isCompleted: false,
              createdAt: DateTime.now(),
            ),
          );
        }

        // Cancel notifications for old task; schedule next occurrence as one-off
        if (task.id != null) {
          await _notificationService.cancelTaskNotifications(task.id!);
        }
        if (nextDueTime != null) {
          final baseId = (createdNext.id ?? 0) * 1000;
          await _notificationService.scheduleTaskNotification(
            createdNext,
            notificationId: baseId + 2,
            titleOverride: '📋 Task Due: ${createdNext.title}',
          );
          // One-off reminder 5 minutes before
          final reminderTime = nextDueTime.subtract(const Duration(minutes: 5));
          if (reminderTime.isAfter(DateTime.now())) {
            await _notificationService.scheduleTaskNotification(
              createdNext.copyWith(dueTime: reminderTime),
              notificationId: baseId + 1,
              titleOverride: '⏰ Reminder: ${createdNext.title}',
            );
          }
        }

        // Mark the old task as completed so it appears in Completed tab
        final completedTask = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await _dbHelper.updateTask(completedTask);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task completed! Next scheduled.')),
          );
        }
      } else {
        // Non-repeating or other types
        final updatedTask = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await _dbHelper.updateTask(updatedTask);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task completed! 🎉')),
          );
        }
      }
    } else {
      // Marking task as incomplete
      final updatedTask = task.copyWith(
        isCompleted: false,
        completedAt: null,
      );
      await _dbHelper.updateTask(updatedTask);
    }
    
    _loadTasks();
  }

  DateTime _nextWeeklyDate(DateTime from, List<int> selectedDays) {
    if (selectedDays.isEmpty) return from.add(const Duration(days: 7));
    final fromIndex = from.weekday - 1;
    for (int i = 1; i <= 7; i++) {
      final idx = (fromIndex + i) % 7;
      if (selectedDays.contains(idx)) {
        return from.add(Duration(days: i));
      }
    }
    return from.add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No repeating tasks',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a task with repeat options',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(task: task),
                            ),
                          );
                          _loadTasks();
                        },
                        onToggleComplete: () => _toggleTaskCompletion(task),
                        onEdit: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditTaskScreen(task: task),
                            ),
                          );
                          _loadTasks();
                        },
                        onDelete: () => _deleteTask(task),
                        showRepeatBadge: true,
                      );
                    },
                  ),
                ),
      floatingActionButton: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (themeProvider.useGradient) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeProvider.gradientStartColor, themeProvider.gradientEndColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddEditTaskScreen(isRepeating: true),
                    ),
                  );
                  _loadTasks();
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add),
              ),
            );
          }
          return FloatingActionButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddEditTaskScreen(isRepeating: true),
                ),
              );
              _loadTasks();
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
