import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> connectionStatusController = StreamController<bool>.broadcast();
  
  bool _hasConnection = false;
  bool get hasConnection => _hasConnection;

  Future<void> initialize() async {
    // Check initial connection status
    await _updateConnectionStatus();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      await _updateConnectionStatus();
    });
  }

  Future<void> _updateConnectionStatus() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      
      // Check if there's any active connection
      _hasConnection = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
      );
      
      connectionStatusController.add(_hasConnection);
    } catch (e) {
      _hasConnection = false;
      connectionStatusController.add(false);
    }
  }

  Future<bool> checkConnection() async {
    await _updateConnectionStatus();
    return _hasConnection;
  }

  void dispose() {
    connectionStatusController.close();
  }
}
