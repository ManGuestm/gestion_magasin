import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TabNavigationWidget extends StatefulWidget {
  final Widget child;
  final List<FocusNode> focusNodes;

  const TabNavigationWidget({
    super.key,
    required this.child,
    required this.focusNodes,
  });

  @override
  State<TabNavigationWidget> createState() => _TabNavigationWidgetState();
}

class _TabNavigationWidgetState extends State<TabNavigationWidget> {
  int _currentFocusIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _previousField();
        return KeyEventResult.handled;
      } else {
        _nextField();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _nextField() {
    if (_currentFocusIndex < widget.focusNodes.length - 1) {
      _currentFocusIndex++;
      widget.focusNodes[_currentFocusIndex].requestFocus();
    }
  }

  void _previousField() {
    if (_currentFocusIndex > 0) {
      _currentFocusIndex--;
      widget.focusNodes[_currentFocusIndex].requestFocus();
    }
  }

  void updateCurrentIndex(FocusNode focusNode) {
    final index = widget.focusNodes.indexOf(focusNode);
    if (index != -1) {
      _currentFocusIndex = index;
    }
  }
}

mixin TabNavigationMixin<T extends StatefulWidget> on State<T> {
  final List<FocusNode> _focusNodes = [];
  int _currentFocusIndex = 0;

  FocusNode createFocusNode() {
    final node = FocusNode();
    _focusNodes.add(node);
    return node;
  }

  void nextField() {
    if (_currentFocusIndex < _focusNodes.length - 1) {
      _currentFocusIndex++;
      _focusNodes[_currentFocusIndex].requestFocus();
    }
  }

  void previousField() {
    if (_currentFocusIndex > 0) {
      _currentFocusIndex--;
      _focusNodes[_currentFocusIndex].requestFocus();
    }
  }

  KeyEventResult handleTabNavigation(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        previousField();
        return KeyEventResult.handled;
      } else {
        nextField();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void updateFocusIndex(FocusNode focusNode) {
    final index = _focusNodes.indexOf(focusNode);
    if (index != -1) {
      _currentFocusIndex = index;
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      if (!node.debugDisposed) {
        node.dispose();
      }
    }
    _focusNodes.clear();
    super.dispose();
  }
}