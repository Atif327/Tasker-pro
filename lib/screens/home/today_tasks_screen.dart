import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../database/database_helper.dart';
import '../../models/task_model.dart';
import '../../models/subtask_model.dart';
import '../../models/category_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/biometric_service.dart';
import '../tasks/add_edit_task_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/task_card.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../providers/theme_provider.dart';
import '../../providers/theme_provider.dart';

enum TaskSortType { date, priority, alphabetical }

class TodayTasksScreen extends StatefulWidget {
  const TodayTasksScreen({Key? key}) : super(key: key);

  @override
  State<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends State<TodayTasksScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService.instance;
  final BiometricService _biometricService = BiometricService.instance;
  List<Task> _tasks = [];
  List<Task> _allTasks = [];
  bool _isLoading = true;
  TaskSortType _sortType = TaskSortType.date;
  bool _isMultiSelectMode = false;
  Set<int> _selectedTaskIds = {};
  
  // Filter state
  Set<String> _selectedCategories = {};
  Set<String> _selectedPriorities = {};
  bool? _filterCompleted;

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _loadTasks();
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt('task_sort_type') ?? 0;
    setState(() {
      _sortType = TaskSortType.values[sortIndex];
    });
  }

  Future<void> _saveSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('task_sort_type', _sortType.index);
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      final tasks = await _dbHelper.getTodayTasks(userId);
      setState(() {
        _allTasks = tasks;
        _tasks = _sortTasks(_applyFilters(tasks));
        _isLoading = false;
      });
    }
  }

  List<Task> _applyFilters(List<Task> tasks) {
    var filtered = tasks;
    
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.category != null && _selectedCategories.contains(task.category);
      }).toList();
    }
    
    if (_selectedPriorities.isNotEmpty) {
      filtered = filtered.where((task) {
        return _selectedPriorities.contains(task.priority);
      }).toList();
    }
    
    if (_filterCompleted != null) {
      filtered = filtered.where((task) => task.isCompleted == _filterCompleted).toList();
    }
    
    return filtered;
  }

  List<Task> _sortTasks(List<Task> tasks) {
    switch (_sortType) {
      case TaskSortType.date:
        tasks.sort((a, b) {
          if (a.dueTime != null && b.dueTime != null) {
            return a.dueTime!.compareTo(b.dueTime!);
          } else if (a.dueTime != null) {
            return -1;
          } else if (b.dueTime != null) {
            return 1;
          }
          return a.dueDate.compareTo(b.dueDate);
        });
        break;
      case TaskSortType.priority:
        tasks.sort((a, b) {
          const priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
          return (priorityOrder[a.priority] ?? 3)
              .compareTo(priorityOrder[b.priority] ?? 3);
        });
        break;
      case TaskSortType.alphabetical:
        tasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return tasks;
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
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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
      if (task.id != null) {
        await _notificationService.cancelNotification(task.id!);
      }
      _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (!task.isCompleted) {
      // Marking task as complete
      if (task.isRepeating && task.repeatType == 'daily') {
        // For daily repeating tasks, mark current task completed
        final completedTask = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await _dbHelper.updateTask(completedTask);

        // Create a new task for the next day (fresh subtasks)
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

        // Duplicate subtasks as unchecked
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

        // Cancel any notifications for the completed task and schedule for new one
        await _notificationService.cancelTaskNotifications(task.id!);
        if (nextDueTime != null) {
          final baseId = (createdNext.id ?? 0) * 1000;
          // Schedule repeating due-time notification
          await _notificationService.scheduleRepeatingTaskNotification(
            createdNext,
            notificationId: baseId + 3,
            titleOverride: '🔄 Recurring Task: ${createdNext.title}',
          );
          // Also schedule repeating reminder 5 minutes before
          final reminderTime = nextDueTime.subtract(const Duration(minutes: 5));
          await _notificationService.scheduleRepeatingTaskNotification(
            createdNext.copyWith(dueTime: reminderTime),
            notificationId: baseId + 1,
            titleOverride: '⏰ Reminder: ${createdNext.title}',
          );
        }
      } else if (task.isRepeating && task.repeatType == 'weekly') {
        // Mark current task completed
        final completedTask = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await _dbHelper.updateTask(completedTask);

        // Determine next occurrence based on selected days (Mon..Sun indices 0..6)
        DateTime base = task.dueDate;
        List<int> days = [];
        if (task.repeatDays != null && task.repeatDays!.isNotEmpty) {
          try {
            days = (jsonDecode(task.repeatDays!) as List).cast<int>();
          } catch (_) {}
        }
        DateTime nextDueDate = _nextWeeklyDate(base, days);
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

        // Duplicate subtasks as unchecked
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

        // Cancel notifications for completed task and schedule the next occurrence (one-off)
        await _notificationService.cancelTaskNotifications(task.id!);
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
      } else {
        // Regular task or non-daily repeating task
        final updatedTask = task.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await _dbHelper.updateTask(updatedTask);
      }
      
      _notificationService.showInstantNotification(
        'Task Completed! 🎉',
        task.title,
      );
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
    if (selectedDays.isEmpty) {
      return from.add(const Duration(days: 7));
    }
    final fromIndex = from.weekday - 1; // DateTime: Mon=1..Sun=7 -> 0..6
    for (int i = 1; i <= 7; i++) {
      final idx = (fromIndex + i) % 7;
      if (selectedDays.contains(idx)) {
        return from.add(Duration(days: i));
      }
    }
    return from.add(const Duration(days: 7));
  }

  Future<void> _bulkComplete() async {
    for (final taskId in _selectedTaskIds) {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await _dbHelper.updateTask(updatedTask);
    }
    setState(() {
      _selectedTaskIds.clear();
      _isMultiSelectMode = false;
    });
    _loadTasks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedTaskIds.length} tasks completed')),
    );
  }

  Future<void> _bulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text('Delete ${_selectedTaskIds.length} selected tasks?'),
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
      for (final taskId in _selectedTaskIds) {
        await _dbHelper.deleteTask(taskId);
        await _notificationService.cancelNotification(taskId);
      }
      setState(() {
        _selectedTaskIds.clear();
        _isMultiSelectMode = false;
      });
      _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasks deleted')),
      );
    }
  }

  Future<void> _showFilterOptions() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;
    
    final categories = await _dbHelper.getCategories(userId);
    
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategories.clear();
                              _selectedPriorities.clear();
                              _filterCompleted = null;
                            });
                            setState(() {
                              _tasks = _sortTasks(_applyFilters(_allTasks));
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = _selectedCategories.contains(cat.name);
                        return FilterChip(
                          label: Text(cat.name),
                          avatar: Icon(cat.iconData, size: 18, color: isSelected ? Colors.white : cat.color),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedCategories.add(cat.name);
                              } else {
                                _selectedCategories.remove(cat.name);
                              }
                            });
                            setState(() {
                              _tasks = _sortTasks(_applyFilters(_allTasks));
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Low', 'Medium', 'High'].map((priority) {
                        final isSelected = _selectedPriorities.contains(priority);
                        return FilterChip(
                          label: Text(priority),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedPriorities.add(priority);
                              } else {
                                _selectedPriorities.remove(priority);
                              }
                            });
                            setState(() {
                              _tasks = _sortTasks(_applyFilters(_allTasks));
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Completed'),
                          selected: _filterCompleted == true,
                          onSelected: (selected) {
                            setModalState(() {
                              _filterCompleted = selected ? true : null;
                            });
                            setState(() {
                              _tasks = _sortTasks(_applyFilters(_allTasks));
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Pending'),
                          selected: _filterCompleted == false,
                          onSelected: (selected) {
                            setModalState(() {
                              _filterCompleted = selected ? false : null;
                            });
                            setState(() {
                              _tasks = _sortTasks(_applyFilters(_allTasks));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('Sort by:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<TaskSortType>(
                    value: _sortType,
                    isExpanded: true,
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(
                        value: TaskSortType.date,
                        child: Text('Date & Time'),
                      ),
                      DropdownMenuItem(
                        value: TaskSortType.priority,
                        child: Text('Priority'),
                      ),
                      DropdownMenuItem(
                        value: TaskSortType.alphabetical,
                        child: Text('Alphabetical'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortType = value;
                          _tasks = _sortTasks(_tasks);
                        });
                        _saveSortPreference();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: (_selectedCategories.isNotEmpty || _selectedPriorities.isNotEmpty || _filterCompleted != null)
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: _showFilterOptions,
                  tooltip: 'Filter tasks',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _isMultiSelectMode ? Icons.close : Icons.checklist,
                    color: _isMultiSelectMode ? Colors.red : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = !_isMultiSelectMode;
                      if (!_isMultiSelectMode) {
                        _selectedTaskIds.clear();
                      }
                    });
                  },
                  tooltip: _isMultiSelectMode ? 'Exit Select Mode' : 'Select Multiple',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks for today',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a new task',
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
                          itemCount: _tasks.length + 1,
                          itemBuilder: (context, index) {
                            // Show ad banner after every 5 tasks or at the end
                            if (index == _tasks.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: AdBannerWidget(),
                              );
                            }
                            final task = _tasks[index];
                            final isSelected = _selectedTaskIds.contains(task.id);
                            return InkWell(
                              onTap: _isMultiSelectMode
                                  ? () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedTaskIds.remove(task.id);
                                        } else {
                                          _selectedTaskIds.add(task.id!);
                                        }
                                      });
                                    }
                                  : null,
                              child: Row(
                                children: [
                                  if (_isMultiSelectMode)
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedTaskIds.add(task.id!);
                                          } else {
                                            _selectedTaskIds.remove(task.id);
                                          }
                                        });
                                      },
                                    ),
                                  Expanded(
                                    child: TaskCard(
                                      task: task,
                                      onTap: _isMultiSelectMode
                                          ? null
                                          : () async {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => TaskDetailScreen(task: task),
                                                ),
                                              );
                                              _loadTasks();
                                            },
                                      onToggleComplete: _isMultiSelectMode
                                          ? null
                                          : () => _toggleTaskCompletion(task),
                                      onEdit: _isMultiSelectMode
                                          ? null
                                          : () async {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => AddEditTaskScreen(task: task),
                                                ),
                                              );
                                              _loadTasks();
                                            },
                                      onDelete: _isMultiSelectMode ? null : () => _deleteTask(task),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode && _selectedTaskIds.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'bulk_complete',
                  onPressed: _bulkComplete,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'bulk_delete',
                  onPressed: _bulkDelete,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                ),
              ],
            )
          : Consumer<ThemeProvider>(
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
                          MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
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
                      MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
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
