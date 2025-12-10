import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../database/database_helper.dart';

class ExportService {
  Future<String> exportToCSV(List<Task> tasks) async {
    List<List<dynamic>> rows = [];
    
    // Header row
    rows.add([
      'Title',
      'Description',
      'Due Date',
      'Due Time',
      'Priority',
      'Category',
      'Status',
      'Is Repeating',
      'Repeat Type',
    ]);

    // Data rows
    for (var task in tasks) {
      rows.add([
        task.title,
        task.description,
        DateFormat('yyyy-MM-dd').format(task.dueDate),
        task.dueTime != null ? DateFormat('HH:mm').format(task.dueTime!) : '',
        _getPriorityText(task.priority),
        task.category ?? '',
        task.isCompleted ? 'Completed' : 'Pending',
        task.isRepeating ? 'Yes' : 'No',
        task.repeatType ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/tasks_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    return path;
  }

  Future<String> exportToPDF(List<Task> tasks, String userName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Task Manager Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generated for: $userName',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            ...tasks.map((task) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          task.title,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: task.isCompleted
                              ? PdfColors.green100
                              : PdfColors.orange100,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          task.isCompleted ? 'Completed' : 'Pending',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(task.description),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      if (task.dueTime != null)
                        pw.Text(
                          ' at ${DateFormat('hh:mm a').format(task.dueTime!)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Priority: ${_getPriorityText(task.priority)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      if (task.category != null && task.category!.isNotEmpty)
                        pw.Text(
                          ' | Category: ${task.category}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      if (task.isRepeating)
                        pw.Text(
                          ' | Repeating: ${task.repeatType}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            )),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/tasks_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    return path;
  }

  Future<void> shareViaEmail(List<Task> tasks) async {
    String text = 'My Tasks\n\n';
    
    for (var task in tasks) {
      text += '${task.isCompleted ? "✓" : "○"} ${task.title}\n';
      if (task.description.isNotEmpty) {
        text += '  ${task.description}\n';
      }
      text += '  Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}';
      if (task.dueTime != null) {
        text += ' at ${DateFormat('hh:mm a').format(task.dueTime!)}';
      }
      text += '\n  Priority: ${_getPriorityText(task.priority)}\n\n';
    }

    await Share.share(
      text,
      subject: 'My Task Manager Tasks',
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 2:
        return 'High';
      case 1:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Future<String> exportToJSON(List<Task> tasks) async {
    final db = DatabaseHelper.instance;
    final List<Map<String, dynamic>> payload = [];

    for (final task in tasks) {
      final subtasks = task.id != null ? await db.getSubTasks(task.id!) : <SubTask>[];
      payload.add({
        'task': task.toMap(),
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
      });
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    final path = '${directory!.path}/tasks_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(path);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return path;
  }

  Future<int> importFromJSON(String filePath, int userId) async {
    final db = DatabaseHelper.instance;
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }
    final content = await file.readAsString();
    final List<dynamic> data = jsonDecode(content);

    int importedTasks = 0;
    await (await db.database).transaction((txn) async {
      for (final entry in data) {
        final Map<String, dynamic> taskMap = Map<String, dynamic>.from(entry['task'] as Map);
        // Ensure task belongs to current user and clear IDs for reinsert
        taskMap.remove('id');
        taskMap['userId'] = userId;
        // Parse dates back to DateTime where needed
        final Task newTask = Task.fromMap(taskMap);
        final taskId = await txn.insert('tasks', newTask.toMap());
        importedTasks++;

        final List<dynamic> subList = (entry['subtasks'] as List? ?? []);
        for (final s in subList) {
          final Map<String, dynamic> subMap = Map<String, dynamic>.from(s as Map);
          subMap.remove('id');
          subMap['taskId'] = taskId;
          final SubTask subTask = SubTask.fromMap(subMap);
          await txn.insert('subtasks', subTask.toMap());
        }
      }
    });

    return importedTasks;
  }
}
