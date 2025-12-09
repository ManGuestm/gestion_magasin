import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database.dart';

class FournisseurNavigationAutocomplete extends StatefulWidget {
  final List<Frn> fournisseurs;
  final Frn? initialFournisseur;
  final Function(Frn?) onFournisseurChanged;
  final FocusNode focusNode;
  final bool enabled;
  final String hintText;
  final InputDecoration? decoration;
  final TextStyle? style;
  final VoidCallback? onTabPressed;
  final VoidCallback? onShiftTabPressed;
  final Frn? selectedFournisseur;

  const FournisseurNavigationAutocomplete({
    super.key,
    required this.fournisseurs,
    this.initialFournisseur,
    required this.onFournisseurChanged,
    required this.focusNode,
    this.enabled = true,
    this.hintText = '',
    this.decoration,
    this.style,
    this.onTabPressed,
    this.onShiftTabPressed,
    this.selectedFournisseur,
  });

  @override
  State<FournisseurNavigationAutocomplete> createState() => _FournisseurNavigationAutocompleteState();
}

class _FournisseurNavigationAutocompleteState extends State<FournisseurNavigationAutocomplete> {
  late TextEditingController _controller;
  List<Frn> _filteredOptions = [];
  int _selectedIndex = -1;
  int _currentIndex = -1;
  String _userInput = '';
  bool _showSuggestion = false;
  bool _isNavigationMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filteredOptions = widget.fournisseurs;
    
    _controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
    
    if (widget.initialFournisseur != null) {
      _setSelectedFournisseur(widget.initialFournisseur!);
    }
  }

  @override
  void didUpdateWidget(FournisseurNavigationAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.selectedFournisseur != oldWidget.selectedFournisseur) {
      if (widget.selectedFournisseur != null) {
        _setSelectedFournisseur(widget.selectedFournisseur!);
      } else {
        _clearSelection();
      }
    }
  }
  
  void _setSelectedFournisseur(Frn fournisseur) {
    final index = widget.fournisseurs.indexWhere((f) => f.rsoc == fournisseur.rsoc);
    if (index != -1) {
      _controller.text = fournisseur.rsoc;
      _currentIndex = index;
      _userInput = fournisseur.rsoc;
      _isNavigationMode = true;
      setState(() {
        _showSuggestion = false;
      });
    }
  }
  
  void _clearSelection() {
    _controller.clear();
    _userInput = '';
    _currentIndex = -1;
    _isNavigationMode = false;
    setState(() {
      _showSuggestion = false;
      _filteredOptions = widget.fournisseurs;
    });
  }

  void _onTextChanged() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.baseOffset == selection.extentOffset || text.length < _userInput.length) {
      _userInput = text;
      _isNavigationMode = false;
    }

    if (mounted && !_isNavigationMode) {
      setState(() {
        _filteredOptions = _userInput.isEmpty
            ? widget.fournisseurs
            : widget.fournisseurs
                .where((option) =>
                    option.rsoc.toLowerCase().startsWith(_userInput.toLowerCase()))
                .toList();

        _selectedIndex = _filteredOptions.isNotEmpty ? 0 : -1;
        _showSuggestion = _userInput.isNotEmpty && _filteredOptions.isNotEmpty;

        if (_showSuggestion &&
            widget.focusNode.hasFocus &&
            selection.baseOffset == selection.extentOffset &&
            _userInput.isNotEmpty) {
          final firstMatch = _filteredOptions[0].rsoc;
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

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      setState(() {
        _showSuggestion = false;
      });
    }
  }

  void _selectOption(Frn option) {
    final displayString = option.rsoc;
    _controller.text = displayString;
    _userInput = displayString;
    _currentIndex = widget.fournisseurs.indexOf(option);
    setState(() {
      _showSuggestion = false;
      _selectedIndex = -1;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFournisseurChanged(option);
      }
    });
  }

  void _navigateInAutocomplete(bool next) {
    if (_filteredOptions.isEmpty) return;

    if (next) {
      _selectedIndex = (_selectedIndex + 1) % _filteredOptions.length;
    } else {
      _selectedIndex = _selectedIndex <= 0 ? _filteredOptions.length - 1 : _selectedIndex - 1;
    }

    final selectedOption = _filteredOptions[_selectedIndex];
    final displayString = selectedOption.rsoc;

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

  void _navigateInAllFournisseurs(bool next) {
    if (widget.fournisseurs.isEmpty) return;

    if (next) {
      _currentIndex = (_currentIndex + 1) % widget.fournisseurs.length;
    } else {
      _currentIndex = _currentIndex <= 0 ? widget.fournisseurs.length - 1 : _currentIndex - 1;
    }

    final fournisseur = widget.fournisseurs[_currentIndex];
    _controller.text = fournisseur.rsoc;
    _isNavigationMode = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFournisseurChanged(fournisseur);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (_isNavigationMode) {
              _navigateInAllFournisseurs(false);
            } else {
              _navigateInAutocomplete(false);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_isNavigationMode) {
              _navigateInAllFournisseurs(true);
            } else {
              _navigateInAutocomplete(true);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (!_isNavigationMode && _selectedIndex >= 0 && _selectedIndex < _filteredOptions.length) {
              _selectOption(_filteredOptions[_selectedIndex]);
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.tab) {
            final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.shiftLeft) ||
                HardwareKeyboard.instance.logicalKeysPressed
                    .contains(LogicalKeyboardKey.shiftRight);

            if (!_isNavigationMode && _selectedIndex >= 0 && _selectedIndex < _filteredOptions.length) {
              _selectOption(_filteredOptions[_selectedIndex]);
            }

            if (isShiftPressed) {
              widget.onShiftTabPressed?.call();
            } else {
              widget.onTabPressed?.call();
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controller.text.isEmpty) {
              _controller.clear();
              _userInput = '';
              _isNavigationMode = false;
              return KeyEventResult.handled;
            }
            if (_controller.selection.start != _controller.selection.end) {
              _controller.removeListener(_onTextChanged);
              _controller.text = _userInput;
              _controller.selection = TextSelection.collapsed(offset: _userInput.length);
              _controller.addListener(_onTextChanged);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        style: widget.style,
        decoration: widget.decoration ?? InputDecoration(hintText: widget.hintText),
        onTap: () {
          setState(() {
            _userInput = _controller.text;
            _showSuggestion = _userInput.isNotEmpty;
            _isNavigationMode = false;
          });
        },
        onSubmitted: (value) {
          if (!_isNavigationMode && _selectedIndex >= 0 && _selectedIndex < _filteredOptions.length) {
            _selectOption(_filteredOptions[_selectedIndex]);
          }
          widget.onTabPressed?.call();
        },
      ),
    );
  }
}