import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._internal();
  factory BiometricService() => instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _appPinKey = 'app_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _autoLockTimeoutKey = 'auto_lock_timeout';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _deleteProtectionKey = 'delete_protection_enabled';

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics are available (enrolled)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      // First authenticate to enable
      final authenticated = await authenticate(
        reason: 'Authenticate to enable biometric login',
      );
      
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if device supports biometric authentication
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        print('Biometric: Device not supported');
        return false;
      }

      // Check if biometrics can be used (enrolled)
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        print('Biometric: No biometrics enrolled');
        return false;
      }

      // Get available biometrics to ensure at least one is available
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('Biometric: No biometric types available');
        return false;
      }

      print('Biometric: Attempting authentication with ${availableBiometrics.length} methods');

      // Attempt authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false,
          sensitiveTransaction: false,
        ),
      );

      print('Biometric: Authentication result: $authenticated');
      return authenticated;
    } catch (e) {
      print('Biometric: Authentication error: $e');
      return false;
    }
  }

  /// Get biometric type name for display
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.isEmpty) {
      return 'Biometric';
    }
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Pattern/PIN';
    }
    
    return 'Biometric';
  }

  // ==================== PIN Methods ====================
  
  /// Check if PIN is enabled
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  /// Set up a new PIN
  Future<bool> setupPin(String pin) async {
    if (pin.length < 4) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appPinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
    return true;
  }

  /// Change existing PIN (requires old PIN verification)
  Future<bool> changePin(String oldPin, String newPin) async {
    if (newPin.length < 4) return false;
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appPinKey, newPin);
    return true;
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_appPinKey);
    return storedPin == pin;
  }

  /// Disable PIN
  Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appPinKey);
    await prefs.setBool(_pinEnabledKey, false);
  }

  // ==================== Auto-Lock Methods ====================
  
  /// Get auto-lock timeout in seconds (default 30)
  Future<int> getAutoLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoLockTimeoutKey) ?? 30;
  }

  /// Set auto-lock timeout
  Future<void> setAutoLockTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockTimeoutKey, seconds);
  }

  /// Update last active time
  Future<void> updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if app should be locked based on timeout
  Future<bool> shouldLockApp() async {
    final isPinOn = await isPinEnabled();
    final isBioOn = await isBiometricEnabled();
    
    if (!isPinOn && !isBioOn) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt(_lastActiveTimeKey);
    if (lastActive == null) return true;
    
    final timeout = await getAutoLockTimeout();
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = (now - lastActive) ~/ 1000;
    
    return elapsed >= timeout;
  }

  // ==================== Delete Protection Methods ====================
  
  /// Check if delete protection is enabled
  Future<bool> isDeleteProtectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deleteProtectionKey) ?? false;
  }

  /// Enable delete protection
  Future<void> enableDeleteProtection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deleteProtectionKey, true);
  }

  /// Disable delete protection
  Future<void> disableDeleteProtection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deleteProtectionKey, false);
  }

  /// Authenticate for delete (biometric or PIN)
  Future<bool> authenticateForDelete(BuildContext context) async {
    final isBioEnabled = await isBiometricEnabled();
    final isPinOn = await isPinEnabled();
    
    if (isBioEnabled) {
      return await authenticate(reason: 'Authenticate to delete task');
    } else if (isPinOn) {
      // Show PIN dialog
      return await _showPinDialog(context, 'Enter PIN to delete');
    }
    
    return true; // No protection enabled
  }

  Future<bool> _showPinDialog(BuildContext context, String title) async {
    String enteredPin = '';
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => enteredPin = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final isValid = await verifyPin(enteredPin);
                    Navigator.pop(ctx, isValid);
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }
}
