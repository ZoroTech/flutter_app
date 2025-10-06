import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();
  
  NetworkService._();

  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  bool _isConnected = true;
  Timer? _connectivityTimer;

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isConnected => _isConnected;

  void startMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
    
    // Initial check
    _checkConnectivity();
  }

  void stopMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (isConnected != _isConnected) {
        _isConnected = isConnected;
        _connectivityController.add(_isConnected);
        
        if (kDebugMode) {
          print('Network status changed: ${_isConnected ? "Connected" : "Disconnected"}');
        }
      }
      
      return _isConnected;
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
        
        if (kDebugMode) {
          print('Network check failed: $e');
        }
      }
      return false;
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<T?> executeWithConnectivityCheck<T>(
    Future<T> Function() operation, {
    String? offlineMessage,
  }) async {
    final hasConnection = await hasInternetConnection();
    
    if (!hasConnection) {
      throw NetworkException(
        offlineMessage ?? 'No internet connection. Please check your network and try again.',
      );
    }
    
    try {
      return await operation();
    } catch (e) {
      // Check if error is network-related
      if (e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('timeout')) {
        throw NetworkException('Network error occurred. Please try again.');
      }
      rethrow;
    }
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}