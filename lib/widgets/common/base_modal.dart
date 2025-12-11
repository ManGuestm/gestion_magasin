import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import '../../services/keyboard_service.dart';

class BaseModal extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double width;
  final double height;
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onNew;
  final VoidCallback? onDelete;
  final VoidCallback? onSearch;
  final VoidCallback? onRefresh;
  final VoidCallback? onPrint;

  const BaseModal({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.width = 900,
    this.height = 600,
    this.onClose,
    this.onSave,
    this.onCancel,
    this.onNew,
    this.onDelete,
    this.onSearch,
    this.onRefresh,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: KeyboardShortcutHandler(
        shortcuts: {
          if (onSave != null) LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): onSave!,
          if (onCancel != null) LogicalKeySet(LogicalKeyboardKey.escape): onCancel!,
          if (onNew != null) LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): onNew!,
          if (onRefresh != null) LogicalKeySet(LogicalKeyboardKey.f5): onRefresh!,
        },
        child: Dialog(
          backgroundColor: Colors.grey[100],
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: content),
                if (actions != null) _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions!,
      ),
    );
  }
}
