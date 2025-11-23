import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormShortcutsWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onF2;
  final VoidCallback? onF3;
  final VoidCallback? onF4;
  final VoidCallback? onF5;
  final VoidCallback? onEnter;
  final VoidCallback? onEscape;
  final VoidCallback? onCtrlS;
  final VoidCallback? onCtrlN;
  final VoidCallback? onDelete;
  final VoidCallback? onTab;
  final VoidCallback? onShiftTab;

  const FormShortcutsWidget({
    super.key,
    required this.child,
    this.onF2,
    this.onF3,
    this.onF4,
    this.onF5,
    this.onEnter,
    this.onEscape,
    this.onCtrlS,
    this.onCtrlN,
    this.onDelete,
    this.onTab,
    this.onShiftTab,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.f2):  _F2Intent(),
        LogicalKeySet(LogicalKeyboardKey.f3): _F3Intent(),
        LogicalKeySet(LogicalKeyboardKey.f4): _F4Intent(),
        LogicalKeySet(LogicalKeyboardKey.f5): _F5Intent(),
        LogicalKeySet(LogicalKeyboardKey.enter):  _EnterIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): _EscapeIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): _CtrlSIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): _CtrlNIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): _DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.tab): _TabIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): _ShiftTabIntent(),
      },
      child: Actions(
        actions: {
          _F2Intent: CallbackAction<_F2Intent>(onInvoke: (_) => onF2?.call()),
          _F3Intent: CallbackAction<_F3Intent>(onInvoke: (_) => onF3?.call()),
          _F4Intent: CallbackAction<_F4Intent>(onInvoke: (_) => onF4?.call()),
          _F5Intent: CallbackAction<_F5Intent>(onInvoke: (_) => onF5?.call()),
          _EnterIntent: CallbackAction<_EnterIntent>(onInvoke: (_) => onEnter?.call()),
          _EscapeIntent: CallbackAction<_EscapeIntent>(onInvoke: (_) => onEscape?.call()),
          _CtrlSIntent: CallbackAction<_CtrlSIntent>(onInvoke: (_) => onCtrlS?.call()),
          _CtrlNIntent: CallbackAction<_CtrlNIntent>(onInvoke: (_) => onCtrlN?.call()),
          _DeleteIntent: CallbackAction<_DeleteIntent>(onInvoke: (_) => onDelete?.call()),
          _TabIntent: CallbackAction<_TabIntent>(onInvoke: (_) => onTab?.call()),
          _ShiftTabIntent: CallbackAction<_ShiftTabIntent>(onInvoke: (_) => onShiftTab?.call()),
        },
        child: child,
      ),
    );
  }
}

class _F2Intent extends Intent {}
class _F3Intent extends Intent {}
class _F4Intent extends Intent {}
class _F5Intent extends Intent {}
class _EnterIntent extends Intent {}
class _EscapeIntent extends Intent {}
class _CtrlSIntent extends Intent {}
class _CtrlNIntent extends Intent {}
class _DeleteIntent extends Intent {}
class _TabIntent extends Intent {}
class _ShiftTabIntent extends Intent {}