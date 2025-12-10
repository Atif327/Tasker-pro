import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'auth/signin_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService.instance;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!mounted) return;

    // Check if biometric is enabled and user is logged in
    if (isLoggedIn) {
      final biometricEnabled = await _biometricService.isBiometricEnabled();
      
      if (biometricEnabled && !_isAuthenticating) {
        _isAuthenticating = true;
        await _authenticateWithBiometric();
      } else {
        _navigateToHome();
      }
    } else {
      _navigateToSignIn();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to access your tasks',
        useErrorDialogs: true,
      );

      if (!mounted) return;

      if (authenticated) {
        _navigateToHome();
      } else {
        _showAuthenticationFailedDialog();
      }
    } catch (e) {
      if (!mounted) return;
      _showAuthenticationFailedDialog();
    }
  }

  void _showAuthenticationFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: const Text('Please authenticate to continue using the app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _isAuthenticating = false;
              _authenticateWithBiometric();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _authService.signOut();
              if (!mounted) return;
              _navigateToSignIn();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _navigateToSignIn() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    size: 80,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Tasker Pro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Plane Smarter, Achieve More',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
