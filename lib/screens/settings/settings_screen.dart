import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../services/notification_service.dart';
import '../../services/biometric_service.dart';
import '../../database/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import '../home/progress_dashboard_screen.dart';
import 'pin_setup_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final ExportService _exportService = ExportService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final BiometricService _biometricService = BiometricService.instance;
  final ImagePicker _picker = ImagePicker();
  
  String _userName = '';
  String _userEmail = '';
  String? _userImagePath;
  String _notificationSound = 'default';
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometric';
  bool _pinEnabled = false;
  int _autoLockTimeout = 30;
  bool _deleteProtectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await _authService.getCurrentUserName();
    final email = await _authService.getCurrentUserEmail();
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('user_profile_image');
    final sound = prefs.getString('notification_sound') ?? 'default';
    
    // Load biometric settings
    final biometricEnabled = await _biometricService.isBiometricEnabled();
    final biometricAvailable = await _biometricService.canCheckBiometrics() || 
                               await _biometricService.isDeviceSupported();
    final biometricType = await _biometricService.getBiometricTypeName();
    
    // Load PIN settings
    final pinEnabled = await _biometricService.isPinEnabled();
    final autoLockTimeout = await _biometricService.getAutoLockTimeout();
    final deleteProtectionEnabled = await _biometricService.isDeleteProtectionEnabled();
    
    setState(() {
      _userName = name ?? '';
      _userEmail = email ?? '';
      _userImagePath = imagePath;
      _notificationSound = sound;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _biometricType = biometricType;
      _pinEnabled = pinEnabled;
      _autoLockTimeout = autoLockTimeout;
      _deleteProtectionEnabled = deleteProtectionEnabled;
    });
  }

  Future<void> _changeNotificationSound() async {
    final selectedSound = await showDialog<String>(
      context: context,
      builder: (context) {
        String temp = _notificationSound;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: const Text('Notification Sound'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Default'),
                    subtitle: const Text('System default sound'),
                    value: 'default',
                    groupValue: temp,
                    onChanged: (v) {
                      if (v != null) {
                        setStateDialog(() => temp = v);
                        Navigator.pop(ctx, v);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Bell'),
                    subtitle: const Text('Classic bell sound'),
                    value: 'notification_alert',
                    groupValue: temp,
                    onChanged: (v) {
                      if (v != null) {
                        setStateDialog(() => temp = v);
                        Navigator.pop(ctx, v);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Chime'),
                    subtitle: const Text('Soft chime sound'),
                    value: 'notification_chime',
                    groupValue: temp,
                    onChanged: (v) {
                      if (v != null) {
                        setStateDialog(() => temp = v);
                        Navigator.pop(ctx, v);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Alert'),
                    subtitle: const Text('Alert tone'),
                    value: 'notification_bell',
                    groupValue: temp,
                    onChanged: (v) {
                      if (v != null) {
                        setStateDialog(() => temp = v);
                        Navigator.pop(ctx, v);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Silent'),
                    subtitle: const Text('No sound'),
                    value: 'silent',
                    groupValue: temp,
                    onChanged: (v) {
                      if (v != null) {
                        setStateDialog(() => temp = v);
                        Navigator.pop(ctx, v);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedSound != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_sound', selectedSound);
      setState(() {
        _notificationSound = selectedSound;
      });
      
      // Reinitialize notification service with new sound settings
      await _notificationService.updateNotificationSettings();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notifications set to: ${_getSoundDisplayName(selectedSound)}')),
      );
    }
  }

  String _getSoundDisplayName(String sound) {
    switch (sound) {
      case 'silent': return 'Silent';
      case 'notification_bell': return 'Alert';
      case 'notification_chime': return 'Chime';
      case 'notification_alert': return 'Bell';
      case 'default': return 'Default';
      default: return 'Default';
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showInstantNotification(
      'Test Notification',
      'Testing ${_getSoundDisplayName(_notificationSound)} sound',
    );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification sent!')),
    );
  }

  // Removed unused _pickImage function

  Future<void> _pickAndCrop(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        final CroppedFile? cropped = await ImageCropper().cropImage(
          sourcePath: image.path,
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Adjust Photo',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
              activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
            ),
            IOSUiSettings(
              title: 'Adjust Photo',
              aspectRatioLockEnabled: true,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          maxWidth: 512,
          maxHeight: 512,
        );

        // If user cancels cropping, keep original selection
        final String finalPath = cropped?.path ?? image.path;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_image', finalPath);
        setState(() {
          _userImagePath = finalPath;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_image');
    setState(() {
      _userImagePath = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo removed')),
    );
  }

  Future<void> _showPhotoOptions() async {
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
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndCrop(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndCrop(ImageSource.gallery);
                },
              ),
              if (_userImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove current photo'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _removeImage();
                  },
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_biometricAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_biometricType is not available on this device'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (value) {
      // Enable biometric
      try {
        // Check biometrics one more time
        final biometrics = await _biometricService.getAvailableBiometrics();
        if (biometrics.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No biometric authentication methods enrolled. Please set up fingerprint or screen lock in device settings.'),
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        final success = await _biometricService.enableBiometric();
        if (success) {
          setState(() {
            _biometricEnabled = true;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType enabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed or cancelled. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Disable biometric
      await _biometricService.disableBiometric();
      setState(() {
        _biometricEnabled = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_biometricType disabled')),
      );
    }
  }

  Future<void> _managePin() async {
    if (_pinEnabled) {
      // Show options: Change PIN or Disable PIN
      await showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Change PIN'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSetupScreen(isChangingPin: true),
                      ),
                    );
                    if (result == true) {
                      _loadUserInfo();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Disable PIN', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _biometricService.disablePin();
                    setState(() => _pinEnabled = false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN disabled')),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    } else {
      // Navigate to setup PIN
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PinSetupScreen(),
        ),
      );
      if (result == true) {
        setState(() => _pinEnabled = true);
      }
    }
  }

  Future<void> _changeAutoLockTimeout() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Auto-Lock Timeout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(
                title: const Text('30 seconds'),
                value: 30,
                groupValue: _autoLockTimeout,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
              RadioListTile<int>(
                title: const Text('1 minute'),
                value: 60,
                groupValue: _autoLockTimeout,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
              RadioListTile<int>(
                title: const Text('2 minutes'),
                value: 120,
                groupValue: _autoLockTimeout,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
              RadioListTile<int>(
                title: const Text('5 minutes'),
                value: 300,
                groupValue: _autoLockTimeout,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
              RadioListTile<int>(
                title: const Text('10 minutes'),
                value: 600,
                groupValue: _autoLockTimeout,
                onChanged: (value) => Navigator.pop(ctx, value),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _biometricService.setAutoLockTimeout(selected);
      setState(() => _autoLockTimeout = selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-lock set to ${_getTimeoutDisplay(selected)}')),
      );
    }
  }

  String _getTimeoutDisplay(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  }

  Future<void> _exportTasks(String format) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;

    final tasks = await _dbHelper.getAllTasks(userId);
    
    if (tasks.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to export')),
      );
      return;
    }

    try {
      String result;
      if (format == 'csv') {
        result = await _exportService.exportToCSV(tasks);
      } else if (format == 'pdf') {
        result = await _exportService.exportToPDF(tasks, _userName);
      } else if (format == 'json') {
        result = await _exportService.exportToJSON(tasks);
      } else {
        await _exportService.shareViaEmail(tasks);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tasks exported successfully to $result')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importBackup() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final count = await _exportService.importFromJSON(path, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count tasks from backup')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _deleteAllData() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text('This will permanently delete all your tasks and subtasks. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    await _dbHelper.deleteAllDataForUser(userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data deleted')),
    );
  }

  void _showColorDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        bool useGradient = themeProvider.useGradient;
        Color solidColor = themeProvider.customPrimaryColor;
        Color gradientStart = themeProvider.gradientStartColor;
        Color gradientEnd = themeProvider.gradientEndColor;
        
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Pick Theme Color'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Use Gradient'),
                    value: useGradient,
                    onChanged: (value) {
                      setState(() => useGradient = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!useGradient) ...[
                    const Text('Solid Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ColorPicker(
                      pickerColor: solidColor,
                      onColorChanged: (color) {
                        setState(() => solidColor = color);
                      },
                      pickerAreaHeightPercent: 0.7,
                    ),
                  ] else ...[
                    const Text('Gradient Start Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ColorPicker(
                      pickerColor: gradientStart,
                      onColorChanged: (color) {
                        setState(() => gradientStart = color);
                      },
                      pickerAreaHeightPercent: 0.5,
                    ),
                    const SizedBox(height: 16),
                    const Text('Gradient End Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ColorPicker(
                      pickerColor: gradientEnd,
                      onColorChanged: (color) {
                        setState(() => gradientEnd = color);
                      },
                      pickerAreaHeightPercent: 0.5,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (useGradient) {
                    themeProvider.setGradientColors(gradientStart, gradientEnd);
                  } else {
                    themeProvider.setCustomColor(solidColor);
                    themeProvider.toggleGradient(false);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Info Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _userImagePath != null
                              ? FileImage(File(_userImagePath!))
                              : null,
                          child: _userImagePath == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showPhotoOptions,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Change Photo'),
                  ),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _userEmail,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Appearance Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(themeProvider.themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('Auto Dark Mode'),
            subtitle: Text(
              themeProvider.autoThemeEnabled 
                  ? 'Dark mode 7PM-7AM' 
                  : 'Manual theme control',
            ),
            trailing: Switch(
              value: themeProvider.autoThemeEnabled,
              onChanged: (value) => themeProvider.setAutoTheme(value),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.color_lens,
              color: themeProvider.useGradient ? themeProvider.gradientStartColor : themeProvider.customPrimaryColor,
            ),
            title: const Text('Custom Theme Color'),
            subtitle: Text(themeProvider.useGradient ? 'Gradient colors enabled' : 'Solid color'),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: themeProvider.useGradient 
                  ? LinearGradient(
                      colors: [themeProvider.gradientStartColor, themeProvider.gradientEndColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: themeProvider.useGradient ? null : themeProvider.customPrimaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
              ),
            ),
            onTap: () => _showColorDialog(themeProvider),
          ),

          // Notifications Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Notification Sound'),
            subtitle: Text(_getSoundDisplayName(_notificationSound)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changeNotificationSound,
          ),
          ListTile(
            leading: const Icon(Icons.notification_add),
            title: const Text('Test Notification'),
            subtitle: const Text('Send a test notification with current sound'),
            trailing: const Icon(Icons.play_arrow),
            onTap: _testNotification,
          ),
          
          // Categories Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            subtitle: const Text('Create, edit, or delete task categories'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.pushNamed(context, '/category_management');
            },
          ),

          // Security Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(
              _biometricType.contains('Face') 
                  ? Icons.face 
                  : _biometricType.contains('Finger')
                      ? Icons.fingerprint
                      : Icons.lock,
            ),
            title: Text('$_biometricType Authentication'),
            subtitle: Text(
              _biometricAvailable
                  ? 'Secure your app with $_biometricType'
                  : '$_biometricType not available on this device',
            ),
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _biometricAvailable ? _toggleBiometric : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('App PIN'),
            subtitle: Text(_pinEnabled ? 'PIN is enabled' : 'Set up a PIN to lock the app'),
            trailing: TextButton(
              onPressed: _managePin,
              child: Text(_pinEnabled ? 'Manage' : 'Setup'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Auto-Lock Timeout'),
            subtitle: Text('Lock app after ${_getTimeoutDisplay(_autoLockTimeout)} of inactivity'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changeAutoLockTimeout,
            enabled: _pinEnabled || _biometricEnabled,
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Two-Step Delete Protection'),
            subtitle: const Text('Require authentication before deleting tasks'),
            trailing: Switch(
              value: _deleteProtectionEnabled,
              onChanged: (_pinEnabled || _biometricEnabled) ? (value) async {
                if (value) {
                  await _biometricService.enableDeleteProtection();
                } else {
                  await _biometricService.disableDeleteProtection();
                }
                setState(() => _deleteProtectionEnabled = value);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'Delete protection enabled' 
                      : 'Delete protection disabled'),
                  ),
                );
              } : null,
            ),
          ),

          // Export Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Export',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export to CSV'),
            subtitle: const Text('Export all tasks to CSV file'),
            onTap: () => _exportTasks('csv'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Export to PDF'),
            subtitle: const Text('Export all tasks to PDF file'),
            onTap: () => _exportTasks('pdf'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share via Email'),
            subtitle: const Text('Share tasks through email'),
            onTap: () => _exportTasks('email'),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Export Backup (JSON)'),
            subtitle: const Text('Full backup including subtasks and attachments metadata'),
            onTap: () => _exportTasks('json'),
          ),

          // Data Management Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restore_page_outlined),
            title: const Text('Import from Backup'),
            subtitle: const Text('Restore tasks from JSON backup'),
            onTap: _importBackup,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete All Data'),
            subtitle: const Text('Remove all tasks and subtasks'),
            onTap: _deleteAllData,
          ),

          // Insights Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Progress Dashboard'),
            subtitle: const Text('Heatmap, streaks, completion rate, productivity'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProgressDashboardScreen()),
              );
            },
          ),

          // Help & Support Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Help & Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text('Contact Us on WhatsApp'),
            subtitle: const Text('Get help and support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final whatsappUrl = 'https://wa.me/923270728950?text=Hi, I need help with Task Manager app';
              try {
                if (Platform.isAndroid || Platform.isIOS) {
                  // Try to open WhatsApp
                  final Uri uri = Uri.parse(whatsappUrl);
                  await Share.shareUri(uri);
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please install WhatsApp to contact us'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined, color: Colors.blue),
            title: const Text('Share App with Friends'),
            subtitle: const Text('Recommend this app'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Share.share(
                'Check out Task Manager - Organize Your Life! A powerful task management app to boost your productivity.\n\nDownload now!',
                subject: 'Task Manager App',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline, color: Colors.amber),
            title: const Text('Rate Us'),
            subtitle: const Text('Give us 5 stars on Play Store'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your support! Please rate us on Play Store'),
                  duration: Duration(seconds: 2),
                ),
              );
              // You can add Play Store URL here when app is published
              // final url = 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME';
            },
          ),

          // About Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blue),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How we handle your data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.orange),
            title: const Text('Terms & Conditions'),
            subtitle: const Text('Usage terms and agreements'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsConditionsScreen(),
                ),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.design_services),
            title: Text('Design By'),
            subtitle: Text('Atif Choudhary'),
          ),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('About'),
            subtitle: Text('Task Manager - Organize Your Life'),
          ),
        ],
      ),
    );
  }
}
