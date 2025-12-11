import 'package:flutter/material.dart';

import '../../services/validation_service.dart';

class ValidatedTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final ValidationResult Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;

  const ValidatedTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
    this.onChanged,
  });

  @override
  State<ValidatedTextField> createState() => ValidatedTextFieldState();
}

class ValidatedTextFieldState extends State<ValidatedTextField> {
  String? _errorMessage;
  bool _hasBeenTouched = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateField);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateField);
    super.dispose();
  }

  void _validateField() {
    if (!_hasBeenTouched) return;

    final result = widget.validator(widget.controller.text);
    setState(() {
      _errorMessage = result.isValid ? null : result.errorMessage;
    });
  }

  void _onFieldTouched() {
    if (!_hasBeenTouched) {
      setState(() {
        _hasBeenTouched = true;
      });
      _validateField();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          onTap: () {
            _onFieldTouched();
            widget.onTap?.call();
          },
          onChanged: (value) {
            _onFieldTouched();
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            border: const OutlineInputBorder(),
            errorText: _errorMessage,
            errorBorder: _errorMessage != null
                ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2))
                : null,
            focusedErrorBorder: _errorMessage != null
                ? const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2))
                : null,
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Valide le champ manuellement
  bool validate() {
    _onFieldTouched();
    final result = widget.validator(widget.controller.text);
    setState(() {
      _errorMessage = result.isValid ? null : result.errorMessage;
    });
    return result.isValid;
  }
}

/// Widget pour valider plusieurs champs à la fois
class ValidationGroup extends StatefulWidget {
  final List<GlobalKey<ValidatedTextFieldState>> fieldKeys;
  final Widget child;

  const ValidationGroup({super.key, required this.fieldKeys, required this.child});

  @override
  State<ValidationGroup> createState() => _ValidationGroupState();
}

class _ValidationGroupState extends State<ValidationGroup> {
  /// Valide tous les champs du groupe
  bool validateAll() {
    bool allValid = true;
    for (final key in widget.fieldKeys) {
      final isValid = key.currentState?.validate() ?? false;
      if (!isValid) allValid = false;
    }
    return allValid;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
