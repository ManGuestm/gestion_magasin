import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

mixin OptimizedModalMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  
  void setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildErrorMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: AppConstants.defaultFontSize,
        ),
      ),
    );
  }

  Widget buildEmptyMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: AppConstants.defaultFontSize,
        ),
      ),
    );
  }

  Future<void> safeAsyncOperation(Future<void> Function() operation) async {
    if (_isLoading) return;
    
    setLoading(true);
    try {
      await operation();
    } catch (e) {
      debugPrint('Error in async operation: $e');
    } finally {
      setLoading(false);
    }
  }
}