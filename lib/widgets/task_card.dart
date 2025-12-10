import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/task_model.dart';
import '../database/database_helper.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showRepeatBadge;
  final bool enableSwipeToDelete;
  final bool showCompletedBadge;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.showRepeatBadge = false,
    this.enableSwipeToDelete = false,
    this.showCompletedBadge = false,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _completedSubtasks = 0;
  int _totalSubtasks = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadSubtasks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSubtasks() async {
    if (widget.task.id != null) {
      final subtasks = await DatabaseHelper.instance.getSubTasks(widget.task.id!);
      setState(() {
        _totalSubtasks = subtasks.length;
        _completedSubtasks = subtasks.where((s) => s.isCompleted).length;
      });
    }
  }

  void _handleToggle() {
    if (widget.onToggleComplete != null) {
      _animationController.forward().then((_) {
        _animationController.reverse();
        widget.onToggleComplete!();
      });
    }
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case 2:
        return Colors.red;
      case 1:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _getPriorityText() {
    switch (widget.task.priority) {
      case 2:
        return 'High';
      case 1:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _getRepeatText() {
    if (!widget.task.isRepeating) return '';
    if (widget.task.repeatType == 'daily') return 'Daily';
    if (widget.task.repeatType == 'weekly' && widget.task.repeatDays != null) {
      final days = (jsonDecode(widget.task.repeatDays!) as List).cast<int>();
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days.map((d) => dayNames[d]).join(', ');
    }
    return '';
  }

  int _getAttachmentCount() {
    if (widget.task.attachments == null || widget.task.attachments!.isEmpty) {
      return 0;
    }
    try {
      final list = jsonDecode(widget.task.attachments!) as List;
      return list.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachmentCount = _getAttachmentCount();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Slidable(
          key: ValueKey(
            'task-${widget.task.id ?? widget.task.title}-${widget.task.createdAt.millisecondsSinceEpoch}',
          ),
          enabled: (widget.onEdit != null || widget.onDelete != null) || widget.onToggleComplete != null,
          startActionPane: widget.enableSwipeToDelete
              ? ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  dismissible: DismissiblePane(
                    onDismissed: () => widget.onDelete?.call(),
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (_) => widget.onDelete?.call(),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                      autoClose: false,
                    ),
                  ],
                )
              : widget.onToggleComplete == null
                  ? null
                  : ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (_) => _handleToggle(),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          icon: Icons.check_circle,
                          label: 'Complete',
                        ),
                      ],
                    ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              if (widget.onEdit != null)
                SlidableAction(
                  onPressed: (_) => widget.onEdit!(),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Edit',
                ),
              if (widget.onDelete != null)
                SlidableAction(
                  onPressed: (_) => widget.onDelete!(),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
            ],
          ),
          child: Card(
            elevation: 2,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.onToggleComplete != null)
                          InkWell(
                            onTap: _handleToggle,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.task.isCompleted ? Colors.green : Colors.grey,
                                  width: 2,
                                ),
                                color: widget.task.isCompleted ? Colors.green : Colors.transparent,
                              ),
                              child: widget.task.isCompleted
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                        if (widget.onToggleComplete != null)
                          const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: widget.task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (widget.task.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    widget.task.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      decoration: widget.task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              if (widget.showCompletedBadge)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Completed!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getPriorityText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPriorityColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Subtask Progress Bar
                    if (_totalSubtasks > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtasks: $_completedSubtasks/$_totalSubtasks',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${((_completedSubtasks / _totalSubtasks) * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _completedSubtasks / _totalSubtasks,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _completedSubtasks == _totalSubtasks
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(widget.task.dueDate),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (widget.task.dueTime != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('hh:mm a').format(widget.task.dueTime!),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                        if (attachmentCount > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.attach_file, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '$attachmentCount',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                        if (widget.task.isRepeating && widget.showRepeatBadge) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.repeat, size: 14, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text(
                            _getRepeatText(),
                            style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                          ),
                        ],
                        if (widget.task.category != null && widget.task.category!.isNotEmpty) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.task.category!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
