import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../models/category_model.dart';
import '../models/comment_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add attachments column to tasks table
      await db.execute('ALTER TABLE tasks ADD COLUMN attachments TEXT');
    }
    if (oldVersion < 3) {
      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          name TEXT NOT NULL,
          colorValue TEXT NOT NULL,
          icon TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      
      // Create comments table
      await db.execute('''
        CREATE TABLE comments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          taskId INTEGER NOT NULL,
          userId INTEGER NOT NULL,
          userName TEXT NOT NULL,
          text TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT,
          FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType,
        password $textType,
        name $textType,
        createdAt $textType
      )
    ''');

    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        userId $intType,
        title $textType,
        description TEXT,
        dueDate $textType,
        dueTime TEXT,
        isCompleted $boolType,
        isRepeating $boolType,
        repeatType TEXT,
        repeatDays TEXT,
        createdAt $textType,
        completedAt TEXT,
        priority $intType,
        category TEXT,
        attachments TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // SubTasks table
    await db.execute('''
      CREATE TABLE subtasks (
        id $idType,
        taskId $intType,
        title $textType,
        isCompleted $boolType,
        createdAt $textType,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Settings table for user preferences
    await db.execute('''
      CREATE TABLE settings (
        id $idType,
        userId $intType,
        themeMode TEXT,
        notificationSound TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        userId $intType,
        name $textType,
        colorValue $textType,
        icon $textType,
        createdAt $textType,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Comments table
    await db.execute('''
      CREATE TABLE comments (
        id $idType,
        taskId $intType,
        userId $intType,
        userName $textType,
        text $textType,
        createdAt $textType,
        updatedAt TEXT,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // User CRUD Operations
  Future<User> createUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Task CRUD Operations
  Future<Task> createTask(Task task) async {
    final db = await database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<List<Task>> getAllTasks(int userId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dueDate DESC, createdAt DESC',
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTodayTasks(int userId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final result = await db.query(
      'tasks',
      where: 'userId = ? AND isCompleted = 0 AND dueDate >= ? AND dueDate <= ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dueDate ASC',
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getCompletedTasks(int userId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'userId = ? AND isCompleted = 1',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getRepeatingTasks(int userId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'userId = ? AND isRepeating = 1 AND isCompleted = 0',
      whereArgs: [userId],
      orderBy: 'dueDate DESC',
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getIncompleteTasks(int userId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'userId = ? AND isCompleted = 0',
      whereArgs: [userId],
      orderBy: 'dueDate ASC, createdAt ASC',
    );

    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Task.fromMap(result.first);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SubTask CRUD Operations
  Future<SubTask> createSubTask(SubTask subTask) async {
    final db = await database;
    final id = await db.insert('subtasks', subTask.toMap());
    return subTask.copyWith(id: id);
  }

  Future<List<SubTask>> getSubTasks(int taskId) async {
    final db = await database;
    final result = await db.query(
      'subtasks',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'createdAt ASC',
    );

    return result.map((map) => SubTask.fromMap(map)).toList();
  }

  Future<int> updateSubTask(SubTask subTask) async {
    final db = await database;
    return db.update(
      'subtasks',
      subTask.toMap(),
      where: 'id = ?',
      whereArgs: [subTask.id],
    );
  }

  Future<int> deleteSubTask(int id) async {
    final db = await database;
    return await db.delete(
      'subtasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubTasksByTaskId(int taskId) async {
    final db = await database;
    return await db.delete(
      'subtasks',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteAllDataForUser(int userId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete subtasks of tasks belonging to user
      await txn.rawDelete('DELETE FROM subtasks WHERE taskId IN (SELECT id FROM tasks WHERE userId = ?)', [userId]);
      // Delete comments of tasks belonging to user
      await txn.rawDelete('DELETE FROM comments WHERE taskId IN (SELECT id FROM tasks WHERE userId = ?)', [userId]);
      // Delete tasks
      await txn.delete('tasks', where: 'userId = ?', whereArgs: [userId]);
      // Delete categories
      await txn.delete('categories', where: 'userId = ?', whereArgs: [userId]);
      // Delete settings for user
      await txn.delete('settings', where: 'userId = ?', whereArgs: [userId]);
      // Optionally keep user account; do not delete from users
    });
  }

  // Category CRUD Operations
  Future<Category> createCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  Future<List<Category>> getCategories(int userId) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Comment CRUD Operations
  Future<Comment> createComment(Comment comment) async {
    final db = await database;
    final id = await db.insert('comments', comment.toMap());
    return comment.copyWith(id: id);
  }

  Future<List<Comment>> getComments(int taskId) async {
    final db = await database;
    final result = await db.query(
      'comments',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Comment.fromMap(map)).toList();
  }

  Future<int> updateComment(Comment comment) async {
    final db = await database;
    return db.update(
      'comments',
      comment.toMap(),
      where: 'id = ?',
      whereArgs: [comment.id],
    );
  }

  Future<int> deleteComment(int id) async {
    final db = await database;
    return await db.delete(
      'comments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}

extension UserExtension on User {
  User copyWith({
    int? id,
    String? email,
    String? password,
    String? name,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
