import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mixin pour la navigation par tabulation dans les formulaires
/// Remplace FormNavigationMixin et TabNavigationMixin

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
      if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight)) {
        previousField();
        return KeyEventResult.handled;
      } else {
        nextField();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult handleKeyEvent(KeyEvent event) => handleTabNavigation(event);

  void updateFocusIndex(FocusNode focusNode) {
    final index = _focusNodes.indexOf(focusNode);
    if (index != -1) {
      _currentFocusIndex = index;
    }
  }

  void focusFirstField() {
    if (_focusNodes.isNotEmpty) {
      _currentFocusIndex = 0;
      _focusNodes[0].requestFocus();
    }
  }

  Widget buildFormField({
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
    TextInputType? keyboardType,
    bool enabled = true,
    bool autofocus = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final node = focusNode ?? createFocusNode();

    return Focus(
      onKeyEvent: (node, event) => handleKeyEvent(event),
      child: SizedBox(
        height: 30,
        child: TextFormField(
          cursorHeight: 15,
          controller: controller,
          focusNode: node,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          onFieldSubmitted: (_) {
            if (onSubmitted != null) {
              onSubmitted();
            } else {
              nextField();
            }
          },
          onTap: () {
            _currentFocusIndex = _focusNodes.indexOf(node);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      try {
        node.dispose();
      } catch (e) {
        // Node already disposed, ignore
      }
    }
    _focusNodes.clear();
    super.dispose();
  }
}
