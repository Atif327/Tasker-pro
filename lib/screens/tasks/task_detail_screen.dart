import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:io';
import '../../database/database_helper.dart';
import '../../models/task_model.dart';
import '../../models/subtask_model.dart';
import '../../models/comment_model.dart';
import '../../services/auth_service.dart';
import '../../services/share_service.dart';
import 'add_edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final AuthService _authService = AuthService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SubTask> _subtasks = [];
  List<Comment> _comments = [];
  late Task _task;
  String? _playingAudio;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadSubTasks();
    _loadComments();
  }

  List<String> _getAttachments() {
    final raw = _task.attachments;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSubTasks() async {
    if (_task.id != null) {
      final subtasks = await _dbHelper.getSubTasks(_task.id!);
      setState(() => _subtasks = subtasks);
    }
  }

  Future<void> _loadComments() async {
    if (_task.id != null) {
      final comments = await _dbHelper.getComments(_task.id!);
      setState(() => _comments = comments);
    }
  }

  Future<void> _shareTask() async {
    final shareText = ShareService.createShareableTaskText(_task, _subtasks);
    await Share.share(shareText, subject: 'Task: ${_task.title}');
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _task.id == null) return;

    final userId = await _authService.getCurrentUserId();
    final userName = await _authService.getCurrentUserName();
    if (userId == null) return;

    final comment = Comment(
      taskId: _task.id!,
      userId: userId,
      userName: userName ?? 'User',
      text: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _dbHelper.createComment(comment);
    _commentController.clear();
    _loadComments();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment added')),
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    await _dbHelper.deleteComment(comment.id!);
    _loadComments();
  }

  Future<void> _playAudio(String path) async {
    if (_playingAudio == path) {
      // Stop if already playing
      await _audioPlayer.stop();
      setState(() => _playingAudio = null);
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _playingAudio = path);
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _playingAudio = null);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: $e')),
      );
    }
  }

  double _getCompletionPercentage() {
    if (_subtasks.isEmpty) return 0.0;
    final completed = _subtasks.where((st) => st.isCompleted).length;
    return completed / _subtasks.length;
  }

  Future<void> _addSubTask() async {
    if (_subtaskController.text.trim().isEmpty || _task.id == null) return;

    final subtask = SubTask(
      taskId: _task.id!,
      title: _subtaskController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _dbHelper.createSubTask(subtask);
    _subtaskController.clear();
    _loadSubTasks();
  }

  Future<void> _toggleSubTask(SubTask subtask) async {
    final updated = subtask.copyWith(isCompleted: !subtask.isCompleted);
    await _dbHelper.updateSubTask(updated);
    _loadSubTasks();
  }

  Future<void> _deleteSubTask(SubTask subtask) async {
    await _dbHelper.deleteSubTask(subtask.id!);
    _loadSubTasks();
  }

  @override
  Widget build(BuildContext context) {
    final completionPercent = _getCompletionPercentage();
    final attachments = _getAttachments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTask,
            tooltip: 'Share Task',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditTaskScreen(task: _task),
                ),
              );
              // Reload task data
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _task.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          _task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: _task.isCompleted ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                      ],
                    ),
                    if (_task.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _task.description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                    const Divider(height: 24),
                    _buildInfoRow(Icons.calendar_today, 'Due Date',
                        DateFormat('MMM dd, yyyy').format(_task.dueDate)),
                    if (_task.dueTime != null)
                      _buildInfoRow(Icons.access_time, 'Time',
                          DateFormat('hh:mm a').format(_task.dueTime!)),
                    _buildInfoRow(Icons.flag, 'Priority', _getPriorityText()),
                    if (_task.category != null && _task.category!.isNotEmpty)
                      _buildInfoRow(Icons.category, 'Category', _task.category!),
                    if (_task.isRepeating)
                      _buildInfoRow(Icons.repeat, 'Repeat',
                          _task.repeatType == 'daily' ? 'Daily' : 'Weekly'),
                  ],
                ),
              ),
            ),

            if (attachments.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attachments',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: attachments.map((path) {
                          final isAudio = path.endsWith('.m4a') || path.endsWith('.mp3') || path.endsWith('.aac');
                          
                          if (isAudio) {
                            return Card(
                              child: InkWell(
                                onTap: () => _playAudio(path),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _playingAudio == path ? Icons.stop : Icons.play_arrow,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Voice Note'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  child: InteractiveViewer(
                                    child: Image.file(File(path), fit: BoxFit.contain),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Subtasks Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtasks',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (_subtasks.isNotEmpty)
                          Text(
                            '${(_getCompletionPercentage() * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                      ],
                    ),
                    if (_subtasks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 10,
                        percent: completionPercent,
                        backgroundColor: Colors.grey[300],
                        progressColor: Colors.blue,
                        barRadius: const Radius.circular(10),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ..._subtasks.map((subtask) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: subtask.isCompleted,
                            onChanged: (_) => _toggleSubTask(subtask),
                          ),
                          title: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSubTask(subtask),
                          ),
                        )),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subtaskController,
                            decoration: const InputDecoration(
                              hintText: 'Add a subtask...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addSubTask(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: Colors.blue,
                          iconSize: 32,
                          onPressed: _addSubTask,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Comments Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.comment, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Comments (${_comments.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Add comment field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _addComment,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                    if (_comments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      ..._comments.map((comment) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      comment.userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    _formatCommentDate(comment.createdAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _deleteComment(comment),
                                    color: Colors.red,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(comment.text),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getPriorityText() {
    switch (_task.priority) {
      case 2:
        return 'High';
      case 1:
        return 'Medium';
      default:
        return 'Low';
    }
  }
}
