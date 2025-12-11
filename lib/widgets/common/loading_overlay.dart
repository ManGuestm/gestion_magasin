import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[const SizedBox(height: 16), Text(message!)],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProgressDialog extends StatelessWidget {
  final String title;
  final String? message;
  final double? progress;
  final VoidCallback? onCancel;

  const ProgressDialog({super.key, required this.title, this.message, this.progress, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress != null) LinearProgressIndicator(value: progress) else const LinearProgressIndicator(),
          const SizedBox(height: 16),
          if (message != null) Text(message!),
        ],
      ),
      actions: [if (onCancel != null) TextButton(onPressed: onCancel, child: const Text('Annuler'))],
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    double? progress,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ProgressDialog(title: title, message: message, progress: progress, onCancel: onCancel),
    );
  }
}

/// Mixin pour faciliter l'utilisation du loading
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _loadingMessage;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  void showLoading([String? message]) {
    setState(() {
      _isLoading = true;
      _loadingMessage = message;
    });
  }

  void hideLoading() {
    setState(() {
      _isLoading = false;
      _loadingMessage = null;
    });
  }

  Future<R> withLoading<R>(Future<R> Function() operation, {String? message}) async {
    showLoading(message);
    try {
      return await operation();
    } finally {
      hideLoading();
    }
  }
}
