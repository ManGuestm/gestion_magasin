import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardService {
  static Widget buildKeyboardHandler({
    required Widget child,
    VoidCallback? onSave,
    VoidCallback? onCancel,
    VoidCallback? onNew,
    VoidCallback? onDelete,
    VoidCallback? onSearch,
    VoidCallback? onRefresh,
    VoidCallback? onPrint,
  }) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): CancelIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): NewIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.f5): RefreshIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP): PrintIntent(),
      },
      child: Actions(
        actions: {
          SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => onSave?.call()),
          CancelIntent: CallbackAction<CancelIntent>(onInvoke: (_) => onCancel?.call()),
          NewIntent: CallbackAction<NewIntent>(onInvoke: (_) => onNew?.call()),
          DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) => onDelete?.call()),
          SearchIntent: CallbackAction<SearchIntent>(onInvoke: (_) => onSearch?.call()),
          RefreshIntent: CallbackAction<RefreshIntent>(onInvoke: (_) => onRefresh?.call()),
          PrintIntent: CallbackAction<PrintIntent>(onInvoke: (_) => onPrint?.call()),
        },
        child: child,
      ),
    );
  }
}

class SaveIntent extends Intent {}

class CancelIntent extends Intent {}

class NewIntent extends Intent {}

class DeleteIntent extends Intent {}

class SearchIntent extends Intent {}

class RefreshIntent extends Intent {}

class PrintIntent extends Intent {}
