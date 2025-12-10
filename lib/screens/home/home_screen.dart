import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/screen_state_service.dart';
import '../../providers/theme_provider.dart';
import '../auth/signin_screen.dart';
import 'today_tasks_screen.dart';
import 'completed_tasks_screen.dart';
import 'repeated_tasks_screen.dart';
import 'progress_dashboard_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserName();
    _initializeScreenStateService();
  }

  Future<void> _initializeScreenStateService() async {
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      ScreenStateService.instance.initialize(userId);
    }
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getCurrentUserName();
    setState(() {
      _userName = name ?? 'User';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    ScreenStateService.instance.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: themeProvider.useGradient
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeProvider.gradientStartColor, themeProvider.gradientEndColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Manager', style: TextStyle(fontSize: 20)),
            Text(
              'Hello, $_userName',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TodayTasksScreen(),
          CompletedTasksScreen(),
          RepeatedTasksScreen(),
          ProgressDashboardScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: themeProvider.useGradient
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeProvider.gradientStartColor, themeProvider.gradientEndColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : BoxDecoration(color: Theme.of(context).primaryColor),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.check_circle), text: 'Completed'),
            Tab(icon: Icon(Icons.repeat), text: 'Repeated'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
    );
  }
}
