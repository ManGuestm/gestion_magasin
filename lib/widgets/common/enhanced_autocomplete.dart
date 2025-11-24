import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnhancedAutocomplete<T> extends StatefulWidget {
  final List<T> options;
  final String Function(T) displayStringForOption;
  final void Function(T) onSelected;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final void Function(String)? onSubmitted;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final void Function(String)? onTextChanged;
  final VoidCallback? onTabPressed;
  final void Function(String)? onFocusLost;

  const EnhancedAutocomplete({
    super.key,
    required this.options,
    required this.displayStringForOption,
    required this.onSelected,
    this.hintText,
    this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.onSubmitted,
    this.onFieldSubmitted,
    this.enabled = true,
    this.onTextChanged,
    this.onTabPressed,
    this.onFocusLost,
  });

  @override
  State<EnhancedAutocomplete<T>> createState() => _EnhancedAutocompleteState<T>();
}

class _EnhancedAutocompleteState<T> extends State<EnhancedAutocomplete<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<T> _filteredOptions = [];
  int _selectedIndex = -1;
  String _userInput = '';
  bool _showSuggestion = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _filteredOptions = widget.options;

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final selection = _controller.selection;

    // Update _userInput only when user is actually typing (not navigating)
    if (selection.baseOffset == selection.extentOffset || text.length < _userInput.length) {
      _userInput = text;
    }

    // Appeler le callback externe si défini
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(text);
    }

    if (mounted) {
      setState(() {
        _filteredOptions = _userInput.isEmpty
            ? widget.options
            : widget.options
                .where((option) =>
                    widget.displayStringForOption(option).toLowerCase().startsWith(_userInput.toLowerCase()))
                .toList();

        _selectedIndex = _filteredOptions.isNotEmpty ? 0 : -1;
        _showSuggestion = _userInput.isNotEmpty && _filteredOptions.isNotEmpty;

        // Auto-complete first match when user types
        if (_showSuggestion &&
            _focusNode.hasFocus &&
            selection.baseOffset == selection.extentOffset &&
            _userInput.isNotEmpty) {
          final firstMatch = widget.displayStringForOption(_filteredOptions[0]);
          if (firstMatch.toLowerCase().startsWith(_userInput.toLowerCase()) && _userInput != firstMatch) {
            _controller.value = TextEditingValue(
              text: firstMatch,
              selection: TextSelection(
                baseOffset: _userInput.length,
                extentOffset: firstMatch.length,
              ),
            );
          }
        }
      });
    }
  }

  /// Méthode publique pour vider le champ
  void clear() {
    _controller.removeListener(_onTextChanged);
    _controller.clear();
    _userInput = '';
    setState(() {
      _filteredOptions = widget.options;
      _selectedIndex = -1;
      _showSuggestion = false;
    });
    _controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestion = false;
      });
      if (widget.onFocusLost != null) {
        widget.onFocusLost!(_controller.text);
      }
    }
  }

  void _selectOption(T option) {
    final displayString = widget.displayStringForOption(option);
    _controller.text = displayString;
    _userInput = displayString;
    setState(() {
      _showSuggestion = false;
      _selectedIndex = -1;
    });
    widget.onSelected(option);
  }

  void _navigateOptions(bool next) {
    if (_filteredOptions.isEmpty) return;

    if (next) {
      _selectedIndex = (_selectedIndex + 1) % _filteredOptions.length;
    } else {
      _selectedIndex = _selectedIndex <= 0 ? _filteredOptions.length - 1 : _selectedIndex - 1;
    }

    final selectedOption = _filteredOptions[_selectedIndex];
    final displayString = widget.displayStringForOption(selectedOption);

    _controller.removeListener(_onTextChanged);
    _controller.value = TextEditingValue(
      text: displayString,
      selection: TextSelection(
        baseOffset: _userInput.length,
        extentOffset: displayString.length,
      ),
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          // Tab : gérer la navigation personnalisée
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            // Si il y a une suggestion, valider d'abord
            if (_selectedIndex >= 0 && _selectedIndex < _filteredOptions.length) {
              _selectOption(_filteredOptions[_selectedIndex]);
              // Après sélection, passer au champ suivant
              if (widget.onTabPressed != null) {
                Future.delayed(const Duration(milliseconds: 50), () {
                  widget.onTabPressed!();
                });
              }
              return KeyEventResult.handled;
            }
            // Appeler le callback de navigation Tab si défini
            if (widget.onTabPressed != null) {
              widget.onTabPressed!();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored; // Laisser Tab faire son travail
          }
          // Backspace : gérer la suppression de la sélection autocomplétée
          else if (event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controller.text.isEmpty) {
              clear();
              return KeyEventResult.handled;
            }
            // Si il y a une sélection (texte en surbrillance), supprimer la sélection
            if (_controller.selection.start != _controller.selection.end) {
              _controller.removeListener(_onTextChanged);
              _controller.text = _userInput;
              _controller.selection = TextSelection.collapsed(offset: _userInput.length);
              _controller.addListener(_onTextChanged);
              return KeyEventResult.handled;
            }
            // Sinon, laisser le comportement normal du backspace
            return KeyEventResult.ignored;
          }
          // Suppression complète avec Escape
          else if (event.logicalKey == LogicalKeyboardKey.escape) {
            clear();
            return KeyEventResult.handled;
          }
          // Navigation dans les options avec flèches gauche/droite
          else if (_filteredOptions.isNotEmpty) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _navigateOptions(true);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _navigateOptions(false);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (_selectedIndex >= 0 && _selectedIndex < _filteredOptions.length) {
                _selectOption(_filteredOptions[_selectedIndex]);
                return KeyEventResult.handled;
              }
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: widget.decoration ??
            InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
        style: widget.style,
        onTap: () {
          setState(() {
            _userInput = _controller.text;
            _showSuggestion = _userInput.isNotEmpty;
          });
        },
        onSubmitted: (value) {
          if (_selectedIndex >= 0 && _selectedIndex < _filteredOptions.length) {
            _selectOption(_filteredOptions[_selectedIndex]);
          } else if (widget.onFieldSubmitted != null) {
            widget.onFieldSubmitted!(value);
          } else if (widget.onSubmitted != null) {
            widget.onSubmitted!(value);
          }
        },
      ),
    );
  }
}
