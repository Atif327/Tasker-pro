import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../tasks/task_detail_screen.dart';
import '../../widgets/task_card.dart';
import '../../widgets/ad_banner_widget.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({Key? key}) : super(key: key);

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
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
      final tasks = await _dbHelper.getCompletedTasks(userId);
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
      _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
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
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No completed tasks yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete tasks to see them here',
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
                      // Show ad banner at the end
                      if (index == _tasks.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: AdBannerWidget(),
                        );
                      }
                      
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
                        onToggleComplete: null, // Disable unchecking completed tasks
                        onEdit: null, // Prevent editing completed tasks
                        onDelete: () => _deleteTask(task),
                        enableSwipeToDelete: true, // Enable swipe left-to-right to delete
                        showCompletedBadge: true, // Show "Completed!" badge
                      );
                    },
                  ),
                ),
    );
  }
}
