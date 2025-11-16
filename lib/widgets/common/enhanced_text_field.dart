import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';

class EnhancedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  final VoidCallback? onEscape;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? hintText;
  final Widget? suffixIcon;
  final bool autofocus;

  const EnhancedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.onSubmitted,
    this.onEscape,
    this.keyboardType,
    this.enabled = true,
    this.validator,
    this.hintText,
    this.suffixIcon,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): _EscapeIntent(),
      },
      child: Actions(
        actions: {
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) => onEscape?.call(),
          ),
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          autofocus: autofocus,
          style: const TextStyle(fontSize: AppConstants.defaultFontSize),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixIcon: suffixIcon,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.defaultPadding / 2,
            ),
            isDense: true,
          ),
          onFieldSubmitted: (_) => onSubmitted?.call(),
        ),
      ),
    );
  }
}

class _EscapeIntent extends Intent {}