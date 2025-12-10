import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../database/database_helper.dart';
import '../../models/task_model.dart';
import '../../models/subtask_model.dart';
import '../../models/category_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  final bool isRepeating;

  const AddEditTaskScreen({
    Key? key,
    this.task,
    this.isRepeating = false,
  }) : super(key: key);

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();
  static const int _maxSubtasks = 7;
  
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService.instance;
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  int _priority = 0;
  String? _selectedCategory;
  List<Category> _categories = [];
  bool _isRepeating = false;
  String _repeatType = 'daily';
  List<int> _selectedDays = [];
  List<String> _subtasks = [];
  List<String> _attachments = [];
  int _reminderMinutes = 0; // 0 means no reminder
  bool _isLoading = false;
  bool _isListeningTitle = false;
  bool _isListeningDescription = false;
  bool _isListeningSubtask = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _isRepeating = widget.isRepeating;
    _loadCategories();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      if (widget.task!.dueTime != null) {
        _selectedTime = TimeOfDay.fromDateTime(widget.task!.dueTime!);
      }
      _priority = widget.task!.priority;
      _selectedCategory = widget.task!.category;
      _isRepeating = widget.task!.isRepeating;
      _repeatType = widget.task!.repeatType ?? 'daily';
      if (widget.task!.repeatDays != null) {
        _selectedDays = (jsonDecode(widget.task!.repeatDays!) as List).cast<int>();
      }
      if (widget.task!.attachments != null && widget.task!.attachments!.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(widget.task!.attachments!);
          _attachments = list.cast<String>();
        } catch (_) {}
      }
      _loadSubtasks();
    }
  }

  Future<void> _loadCategories() async {
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      final categories = await _dbHelper.getCategories(userId);
      setState(() => _categories = categories);
    }
  }

  Future<void> _loadSubtasks() async {
    if (widget.task?.id != null) {
      final subtasks = await _dbHelper.getSubTasks(widget.task!.id!);
      setState(() {
        _subtasks = subtasks.map((st) => st.title).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropAttachment(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (image == null) return;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Attachment',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
          ),
          IOSUiSettings(title: 'Crop Attachment'),
        ],
      );

      final String finalPath = cropped?.path ?? image.path;
      setState(() => _attachments.add(finalPath));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add attachment: $e')),
      );
    }
  }

  Future<void> _showAttachmentOptions() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndCropAttachment(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndCropAttachment(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Record voice note'),
                onTap: () {
                  Navigator.pop(ctx);
                  _recordAudio();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordAudio() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        setState(() => _attachments.add(path));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note saved')),
        );
      }
      return;
    }

    // Request permission
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }

    // Start recording
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      
      setState(() => _isRecording = true);
      
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Recording...'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Tap Stop when done'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final path = await _audioRecorder.stop();
                setState(() => _isRecording = false);
                if (path != null) {
                  setState(() => _attachments.add(path));
                }
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice note saved')),
                );
              },
              child: const Text('Stop Recording'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isRecording = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record: $e')),
      );
    }
  }

  Future<void> _toggleVoiceInput(String field) async {
    // Stop all listening first
    if (_isListeningTitle || _isListeningDescription || _isListeningSubtask) {
      await _speech.stop();
      setState(() {
        _isListeningTitle = false;
        _isListeningDescription = false;
        _isListeningSubtask = false;
      });
      return;
    }

    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required for voice input')),
      );
      return;
    }

    final available = await _speech.initialize(
      onError: (error) {
        setState(() {
          _isListeningTitle = false;
          _isListeningDescription = false;
          _isListeningSubtask = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.errorMsg}')),
        );
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListeningTitle = false;
            _isListeningDescription = false;
            _isListeningSubtask = false;
          });
        }
      },
    );

    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() {
      if (field == 'title') _isListeningTitle = true;
      else if (field == 'description') _isListeningDescription = true;
      else if (field == 'subtask') _isListeningSubtask = true;
    });
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            if (field == 'title') {
              _titleController.text = result.recognizedWords;
              _isListeningTitle = false;
            } else if (field == 'description') {
              _descriptionController.text = result.recognizedWords;
              _isListeningDescription = false;
            } else if (field == 'subtask') {
              _subtaskController.text = result.recognizedWords;
              _isListeningSubtask = false;
            }
          });
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;

    DateTime? dueTime;
    DateTime? reminderTime;
    if (_selectedTime != null) {
      dueTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      // Calculate reminder time
      if (_reminderMinutes > 0) {
        reminderTime = dueTime.subtract(Duration(minutes: _reminderMinutes));
      }
    }

    final task = Task(
      id: widget.task?.id,
      userId: userId,
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _selectedDate,
      dueTime: dueTime,
      isCompleted: widget.task?.isCompleted ?? false,
      isRepeating: _isRepeating,
      repeatType: _isRepeating ? _repeatType : null,
      repeatDays: _isRepeating && _repeatType == 'weekly' && _selectedDays.isNotEmpty
          ? jsonEncode(_selectedDays)
          : null,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      priority: _priority,
      category: _selectedCategory,
      attachments: _attachments.isNotEmpty ? jsonEncode(_attachments) : null,
    );

    if (widget.task == null) {
      final createdTask = await _dbHelper.createTask(task);
      
      // Create subtasks
      for (String subtaskTitle in _subtasks) {
        final subtask = SubTask(
          taskId: createdTask.id!,
          title: subtaskTitle,
          createdAt: DateTime.now(),
        );
        await _dbHelper.createSubTask(subtask);
      }
      
      // Schedule notifications using distinct IDs to avoid overwriting
      final baseId = (createdTask.id ?? 0) * 1000;
      if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskNotification(
          createdTask.copyWith(dueTime: reminderTime),
          notificationId: baseId + 1,
          titleOverride: '⏰ Reminder: ${createdTask.title}',
        );
      }
      if (dueTime != null) {
        if (_isRepeating) {
          await _notificationService.scheduleRepeatingTaskNotification(
            createdTask,
            notificationId: baseId + 3,
            titleOverride: '🔄 Recurring Task: ${createdTask.title}',
          );
        } else {
          await _notificationService.scheduleTaskNotification(
            createdTask,
            notificationId: baseId + 2,
            titleOverride: '📋 Task Due: ${createdTask.title}',
          );
        }
      }
    } else {
      await _dbHelper.updateTask(task);
      
      // Delete old subtasks and create new ones
      await _dbHelper.deleteSubTasksByTaskId(task.id!);
      for (String subtaskTitle in _subtasks) {
        final subtask = SubTask(
          taskId: task.id!,
          title: subtaskTitle,
          createdAt: DateTime.now(),
        );
        await _dbHelper.createSubTask(subtask);
      }
      
      // Schedule notifications
      if (dueTime != null) {
        // Cancel any existing schedules for this task
        await _notificationService.cancelTaskNotifications(widget.task!.id!);
        final baseIdUpdate = (task.id ?? 0) * 1000;
        if (reminderTime != null && reminderTime.isAfter(DateTime.now())) {
          await _notificationService.scheduleTaskNotification(
            task.copyWith(dueTime: reminderTime),
            notificationId: baseIdUpdate + 1,
            titleOverride: '⏰ Reminder: ${task.title}',
          );
        }
        if (_isRepeating) {
          await _notificationService.scheduleRepeatingTaskNotification(
            task,
            notificationId: baseIdUpdate + 3,
            titleOverride: '🔄 Recurring Task: ${task.title}',
          );
        } else {
          await _notificationService.scheduleTaskNotification(
            task,
            notificationId: baseIdUpdate + 2,
            titleOverride: '📋 Task Due: ${task.title}',
          );
        }
      }
    }

    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTask,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.title),
                        suffixIcon: IconButton(
                          icon: Icon(_isListeningTitle ? Icons.mic : Icons.mic_none),
                          onPressed: () => _toggleVoiceInput('title'),
                          color: _isListeningTitle ? Colors.red : Colors.grey,
                          tooltip: 'Voice input',
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                        suffixIcon: IconButton(
                          icon: Icon(_isListeningDescription ? Icons.mic : Icons.mic_none),
                          onPressed: () => _toggleVoiceInput('description'),
                          color: _isListeningDescription ? Colors.red : Colors.grey,
                          tooltip: 'Voice input',
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Subtasks Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtasks ${_subtasks.length}/$_maxSubtasks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._subtasks.asMap().entries.map((entry) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_box_outline_blank, size: 20),
                          title: Text(entry.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () {
                              setState(() => _subtasks.removeAt(entry.key));
                            },
                          ),
                        );
                      }),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              decoration: InputDecoration(
                                hintText: 'Add subtask...',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: Icon(_isListeningSubtask ? Icons.mic : Icons.mic_none),
                                  onPressed: () => _toggleVoiceInput('subtask'),
                                  color: _isListeningSubtask ? Colors.red : Colors.grey,
                                  tooltip: 'Voice input',
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  if (_subtasks.length >= _maxSubtasks) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Maximum $_maxSubtasks subtasks reached')),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _subtasks.add(value.trim());
                                    _subtaskController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: Colors.blue,
                            onPressed: () {
                              if (_subtaskController.text.trim().isNotEmpty) {
                                if (_subtasks.length >= _maxSubtasks) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Maximum $_maxSubtasks subtasks reached')),
                                  );
                                  return;
                                }
                                setState(() {
                                  _subtasks.add(_subtaskController.text.trim());
                                  _subtaskController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Attachments Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Your Attachment here',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickAndCropAttachment(ImageSource.camera),
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.photo_camera, size: 28),
                                      SizedBox(height: 6),
                                      Text('Camera'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickAndCropAttachment(ImageSource.gallery),
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.photo_library, size: 28),
                                      SizedBox(height: 6),
                                      Text('Gallery'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._attachments.asMap().entries.map((entry) {
                            final path = entry.value;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _attachments.removeAt(entry.key));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                child: ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  leading: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                child: ListTile(
                  title: const Text('Due Time'),
                  subtitle: Text(_selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'No time set'),
                  leading: const Icon(Icons.access_time),
                  onTap: _selectTime,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              // Reminder Section
              if (_selectedTime != null) ...[
                const Text('Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('No Reminder'),
                      selected: _reminderMinutes == 0,
                      onSelected: (selected) {
                        if (selected) setState(() => _reminderMinutes = 0);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('5 min before'),
                      selected: _reminderMinutes == 5,
                      onSelected: (selected) {
                        if (selected) setState(() => _reminderMinutes = 5);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('15 min before'),
                      selected: _reminderMinutes == 15,
                      onSelected: (selected) {
                        if (selected) setState(() => _reminderMinutes = 15);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('30 min before'),
                      selected: _reminderMinutes == 30,
                      onSelected: (selected) {
                        if (selected) setState(() => _reminderMinutes = 30);
                      },
                    ),
                  ],
                ),
                Builder(
                  builder: (context) {
                    if (_reminderMinutes > 0 && _selectedTime != null) {
                      final dueTimePreview = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime!.hour,
                        _selectedTime!.minute,
                      );
                      final reminderPreview = dueTimePreview.subtract(Duration(minutes: _reminderMinutes));
                      if (reminderPreview.isBefore(DateTime.now())) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Reminder time would be in the past for the selected time.',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text('Priority', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Low'), icon: Icon(Icons.low_priority)),
                  ButtonSegment(value: 1, label: Text('Medium'), icon: Icon(Icons.priority_high)),
                  ButtonSegment(value: 2, label: Text('High'), icon: Icon(Icons.flag)),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() => _priority = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              
              // Category Selection
              const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No category')),
                  ..._categories.map((category) {
                    return DropdownMenuItem(
                      value: category.name,
                      child: Row(
                        children: [
                          Icon(category.iconData, color: category.color, size: 20),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final cat = _categories.firstWhere(
                    (c) => c.name == _selectedCategory,
                    orElse: () => Category(
                      userId: 0,
                      name: _selectedCategory!,
                      colorValue: '0xFF2196F3',
                      icon: '${Icons.work.codePoint}',
                      createdAt: DateTime.now(),
                    ),
                  );
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: cat.color.withOpacity(0.15),
                      child: Icon(cat.iconData, color: cat.color, size: 18),
                    ),
                    label: Text(cat.name),
                    side: BorderSide(color: cat.color.withOpacity(0.5)),
                    backgroundColor: cat.color.withOpacity(0.08),
                  );
                }),
              ],
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Repeating Task'),
                subtitle: const Text('Task repeats on schedule'),
                value: _isRepeating,
                onChanged: (value) => setState(() => _isRepeating = value),
              ),
              if (_isRepeating) ...[
                const SizedBox(height: 16),
                const Text('Repeat Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Daily'),
                  value: 'daily',
                  groupValue: _repeatType,
                  onChanged: (value) => setState(() => _repeatType = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Weekly (Select Days)'),
                  value: 'weekly',
                  groupValue: _repeatType,
                  onChanged: (value) => setState(() => _repeatType = value!),
                ),
                if (_repeatType == 'weekly') ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final isSelected = _selectedDays.contains(index);
                      return FilterChip(
                        label: Text(days[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(index);
                            } else {
                              _selectedDays.remove(index);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
