# Flutter Tasker Pro

[![Flutter](https://img.shields.io/badge/Flutter-3.35.2-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.0-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive task management application built with Flutter, featuring advanced task organization, voice input, categories, comments, and much more.

**Design By:** Atif Choudhary  
**Version:** 1.0.0

---

## 🌐 Backend (OTP)

- Uses Vercel Serverless API for email OTP (not Firebase Functions).
- Base URL: `https://tasker-pro-otp.vercel.app/api`
   - `POST /send-otp` → `{ email }`
   - `POST /verify-otp` → `{ email, otp, token }`
- Configure client URL in `lib/config.dart`.
- Stateless JWT-based OTP; no database required.

Note: The legacy `functions/` (Firebase Functions) directory was removed to avoid confusion.

## 📱 Screenshots

[Add screenshots of your app here]

---

## ✨ Features

### Core Task Management
- ✅ **Create, Edit, and Delete Tasks** - Full CRUD operations for tasks
- ✅ **Task Details** - Title, description, due date, due time, priority levels
- ✅ **Subtasks** - Break down tasks into smaller actionable items
- ✅ **Task Completion Tracking** - Mark tasks and subtasks as complete
- ✅ **Task Priorities** - Low, Medium, High priority levels with visual indicators
- ✅ **Repeating Tasks** - Daily, weekly, or custom repeat patterns
- ✅ **Task Attachments** - Add photos and voice notes to tasks

### Advanced Features
- 🗂️ **Categories & Tags** - Organize tasks with custom categories (Work, Personal, Shopping, Health, Study, etc.)
- 🎨 **Category Customization** - Custom colors and icons for each category
- 🎤 **Voice Input** - Speech-to-text for task title, description, and subtasks
- 🎙️ **Voice Notes** - Record and attach audio notes to tasks
- 💬 **Comments System** - Add comments and notes to tasks with timestamps
- 📤 **Share Tasks** - Share tasks as formatted text with all details
- 📊 **Progress Dashboard** - View task statistics, streaks, heatmap, and productivity insights
- 🔔 **Smart Notifications** - Customizable task reminders with sound options
- 🔐 **Biometric Authentication** - Fingerprint/Face ID login support
- 🌓 **Dark/Light Theme** - System or manual theme switching with gradient colors
- 📈 **Task Analytics** - Completion rates, time-of-day productivity, and streak tracking

### Data Management
- 💾 **Local Database** - SQLite for offline data storage
- 📦 **Export/Import** - Backup and restore tasks in JSON, CSV, or PDF format
- 🗑️ **Delete All Data** - Clear all tasks and reset app with confirmation
- 🔄 **Data Sync** - Import tasks from JSON backups

---

## 🏗️ Architecture

### Tech Stack
- **Framework:** Flutter 3.35.2
- **Language:** Dart 3.9.0
- **Database:** SQLite (sqflite)
- **State Management:** Provider pattern
- **Local Storage:** SharedPreferences

### Project Structure
```
lib/
├── main.dart                          # App entry point
├── database/
│   └── database_helper.dart           # SQLite database operations
├── models/
│   ├── task_model.dart                # Task data model
│   ├── subtask_model.dart             # Subtask data model
│   ├── user_model.dart                # User data model
│   ├── category_model.dart            # Category data model
│   └── comment_model.dart             # Comment data model
├── providers/
│   └── theme_provider.dart            # Theme state management
├── screens/
│   ├── splash_screen.dart             # App splash screen
│   ├── auth/
│   │   ├── login_screen.dart          # User login
│   │   └── signup_screen.dart         # User registration
│   ├── home/
│   │   ├── home_screen.dart           # Main navigation
│   │   ├── today_tasks_screen.dart    # Today's tasks
│   │   ├── completed_tasks_screen.dart # Completed tasks
│   │   ├── repeated_tasks_screen.dart  # Repeating tasks
│   │   └── progress_dashboard_screen.dart # Analytics dashboard
│   ├── tasks/
│   │   ├── add_edit_task_screen.dart  # Create/edit tasks
│   │   └── task_detail_screen.dart    # Task details & comments
│   └── settings/
│       ├── settings_screen.dart       # App settings
│       └── category_management_screen.dart # Manage categories
├── services/
│   ├── auth_service.dart              # Authentication logic
│   ├── notification_service.dart      # Push notifications
│   ├── biometric_service.dart         # Biometric auth
│   ├── export_service.dart            # Data export/import
│   └── share_service.dart             # Task sharing
└── widgets/
    └── task_card.dart                 # Reusable task card widget
```

### Database Schema

**Database Version:** 3

#### Tables

1. **users**
   - `id` (Primary Key)
   - `email`, `password`, `name`
   - `createdAt`

2. **tasks**
   - `id` (Primary Key)
   - `userId` (Foreign Key → users)
   - `title`, `description`, `dueDate`, `dueTime`
   - `isCompleted`, `isRepeating`, `repeatType`, `repeatDays`
   - `priority`, `category`, `attachments`
   - `createdAt`, `completedAt`

3. **subtasks**
   - `id` (Primary Key)
   - `taskId` (Foreign Key → tasks)
   - `title`, `isCompleted`
   - `createdAt`

4. **categories**
   - `id` (Primary Key)
   - `userId` (Foreign Key → users)
   - `name`, `colorValue`, `icon`
   - `createdAt`

5. **comments**
   - `id` (Primary Key)
   - `taskId` (Foreign Key → tasks)
   - `userId` (Foreign Key → users)
   - `userName`, `text`
   - `createdAt`, `updatedAt`

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core
  cupertino_icons: ^1.0.2
  
  # Database & Storage
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
  
  # State Management
  provider: ^6.1.1
  
  # UI Components
  flutter_slidable: ^3.0.1
  percent_indicator: ^4.2.3
  flutter_colorpicker: ^1.1.0
  
  # Media & Files
  image_picker: ^1.0.7
  image_cropper: ^8.0.2
  file_picker: ^8.0.0
  
  # Audio
  speech_to_text: ^7.0.0
  record: ^5.0.4
  audioplayers: ^6.0.0
  
  # Notifications & Permissions
  awesome_notifications: ^0.10.1
  permission_handler: ^11.1.0
  local_auth: ^2.1.7
  
  # Export & Share
  pdf: ^3.10.7
  csv: ^6.0.0
  share_plus: ^7.2.1
  
  # Utilities
  intl: ^0.20.2
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0 <4.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter_tasker_pro.git
   cd flutter_tasker_pro
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs by ABI
flutter build apk --split-per-abi
```

---

## 📖 User Guide

### Getting Started

#### 1. First Launch
- Open the app and you'll see the splash screen
- Sign up with your name, email, and password
- Or login if you already have an account

#### 2. Creating Your First Task
1. Tap the **+** (FAB) button on the home screen
2. Enter task details:
   - **Title** - Use keyboard or tap 🎤 for voice input
   - **Description** - Add details or use voice input
   - **Due Date & Time** - Select when the task is due
   - **Priority** - Choose Low, Medium, or High
   - **Category** - Select from your categories
   - **Subtasks** - Break down the task (voice input available)
   - **Attachments** - Add photos or voice notes
3. Tap the checkmark ✓ to save

#### 3. Managing Categories
1. Go to **Settings** → **Manage Categories**
2. Tap **+** to create a new category
3. Choose a name, color, and icon
4. Default categories: Work, Personal, Shopping, Health, Study

#### 4. Using Voice Input
- Tap the 🎤 microphone icon next to any text field
- Speak clearly when the icon turns red
- Voice stops automatically after 3 seconds of silence
- Works for: Title, Description, and Subtasks

#### 5. Adding Voice Notes
1. When creating/editing a task, tap "Add Attachment"
2. Select "Record voice note"
3. Record your message
4. Tap "Stop Recording" when done
5. Voice notes appear in task details with a play button

#### 6. Adding Comments
1. Open any task to view details
2. Scroll to the Comments section
3. Type your comment and tap Send
4. Comments show author name and time ago (e.g., "2h ago")
5. Delete comments with the 🗑️ icon

#### 7. Sharing Tasks
1. Open a task
2. Tap the Share icon in the app bar
3. Choose how to share (WhatsApp, Email, etc.)
4. Task is formatted with all details and subtasks

#### 8. Viewing Progress
1. Go to the **Insights** tab
2. View:
   - Current streak and 30-day completion rate
   - Total tasks, completed, pending, and repeating
   - 56-day heatmap showing daily completions
   - Time-of-day productivity chart

#### 9. Exporting Data
1. Go to **Settings**
2. Choose export format:
   - **JSON** - Full backup with all data
   - **CSV** - Spreadsheet format
   - **PDF** - Printable document
3. Files save to Downloads folder

#### 10. Importing Data
1. Go to **Settings** → **Import from JSON**
2. Select your backup file
3. All tasks and subtasks will be restored

---

## 🎨 Customization

### Themes
- **Light/Dark Mode** - Settings → Theme Mode
- **System Theme** - Automatically follows device theme
- **Gradient Colors** - Settings → Custom Theme Color
  - Choose two colors for gradient effect
  - Applies to AppBar, navigation, and FAB

### Notifications
- **Sound Options** - Default, Bell, Chime, Ding, Alert
- **Test Notification** - Send a test to hear the sound
- Notifications appear at task due time and reminder time

### Biometric Authentication
- Enable in Settings → Security
- Supports fingerprint and face recognition
- Adds extra security layer to app login

---

## 🔧 Troubleshooting

### Common Issues

**App won't build**
```bash
flutter clean
flutter pub get
flutter run
```

**Voice input not working**
- Grant microphone permission in device settings
- Check if speech recognition is available on your device

**Audio recording fails**
- Grant microphone permission
- Ensure device has enough storage space

**Database errors after update**
- App automatically migrates to new schema
- If issues persist, use "Delete All Data" in Settings (WARNING: This deletes everything)

**Export not working**
- Grant storage permission
- Check if Downloads folder exists
- Ensure sufficient storage space

---

## 🔐 Permissions

The app requires the following permissions:

- **RECORD_AUDIO** - For voice input and voice notes
- **CAMERA** - For taking photos as attachments
- **READ_EXTERNAL_STORAGE** - For selecting images from gallery
- **WRITE_EXTERNAL_STORAGE** - For exporting data to files
- **USE_BIOMETRIC** - For fingerprint/face authentication
- **VIBRATE** - For notification vibrations
- **RECEIVE_BOOT_COMPLETED** - For rescheduling notifications after reboot

---

## 📝 Code Documentation

### Key Classes

#### DatabaseHelper
Singleton class managing SQLite database operations.

```dart
// Get instance
final db = DatabaseHelper.instance;

// Create task
await db.createTask(task);

// Get all tasks for user
final tasks = await db.getAllTasks(userId);

// Update task
await db.updateTask(task);

// Delete task
await db.deleteTask(taskId);
```

#### ThemeProvider
Manages app theme state with Provider pattern.

```dart
// Access in widget
final themeProvider = Provider.of<ThemeProvider>(context);

// Change theme mode
themeProvider.setThemeMode(ThemeMode.dark);

// Set gradient colors
themeProvider.setGradientColors(color1, color2);
themeProvider.toggleGradient(true);
```

#### NotificationService
Handles all notification scheduling and management.

```dart
final notificationService = NotificationService.instance;

// Schedule notification
await notificationService.scheduleTaskNotification(task);

// Schedule repeating notification
await notificationService.scheduleRepeatingTaskNotification(task);

// Cancel notification
await notificationService.cancelNotification(notificationId);
```

#### AuthService
Manages user authentication and session.

```dart
final authService = AuthService();

// Sign up
final result = await authService.signUp(
  name: name,
  email: email,
  password: password,
);

// Login
final result = await authService.login(email, password);

// Get current user
final userId = await authService.getCurrentUserId();
final email = await authService.getCurrentUserEmail();

// Logout
await authService.logout();
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Developer

**Atif Choudhary**

- Email: [your-email@example.com]
- GitHub: [@yourusername]
- WhatsApp: +923270728950

---

## 🙏 Acknowledgments

- Flutter Documentation: https://docs.flutter.dev/
- Material Design Icons: https://fonts.google.com/icons
- Flutter Community Packages
- All open-source contributors

---

## 📞 Support

For support, email your-email@example.com or contact via WhatsApp at +923270728950.

---

## 🗺️ Roadmap

Future features planned:
- [ ] Cloud sync with Firebase
- [ ] Collaboration features (assign tasks to team members)
- [ ] Calendar integration
- [ ] Home screen widgets
- [ ] Location-based reminders
- [ ] Task templates
- [ ] Multi-language support
- [ ] Desktop and web versions

---

**Made with ❤️ using Flutter**
