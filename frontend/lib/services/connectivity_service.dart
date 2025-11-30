import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _checkTimer;

  void startMonitoring() {
    // Check connectivity immediately
    checkConnectivity();

    // Check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnectivity();
    });
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<bool> checkConnectivity() async {
    if (kIsWeb) {
      // For web, assume online (can't do reliable check)
      _isOnline = true;
      _connectivityController.add(_isOnline);
      return _isOnline;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isOnline = false;
    } catch (_) {
      _isOnline = false;
    }

    _connectivityController.add(_isOnline);
    return _isOnline;
  }

  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}
