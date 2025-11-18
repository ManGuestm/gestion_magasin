import 'package:flutter/material.dart';

mixin FormNavigationMixin<T extends StatefulWidget> on State<T> {
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

    return SizedBox(
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
    );
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
