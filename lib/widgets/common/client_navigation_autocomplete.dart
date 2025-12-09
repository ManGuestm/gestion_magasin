import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database.dart';

class ClientNavigationAutocomplete extends StatefulWidget {
  final List<CltData> clients;
  final CltData? initialClient;
  final Function(CltData?) onClientChanged;
  final FocusNode focusNode;
  final bool enabled;
  final String hintText;
  final InputDecoration? decoration;
  final TextStyle? style;
  final VoidCallback? onTabPressed;
  final VoidCallback? onShiftTabPressed;
  final VoidCallback? onNextClientSet;
  final CltData? selectedClient;

  const ClientNavigationAutocomplete({
    super.key,
    required this.clients,
    this.initialClient,
    required this.onClientChanged,
    required this.focusNode,
    this.enabled = true,
    this.hintText = '',
    this.decoration,
    this.style,
    this.onTabPressed,
    this.onShiftTabPressed,
    this.onNextClientSet,
    this.selectedClient,
  });

  @override
  State<ClientNavigationAutocomplete> createState() => _ClientNavigationAutocompleteState();
}

class _ClientNavigationAutocompleteState extends State<ClientNavigationAutocomplete> {
  late TextEditingController _controller;
  List<CltData> _filteredOptions = [];
  int _selectedIndex = -1;
  int _currentIndex = -1;
  String _userInput = '';
  bool _showSuggestion = false;
  bool _isNavigationMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filteredOptions = widget.clients;
    
    _controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
    
    if (widget.initialClient != null) {
      _setNextClient(widget.initialClient!);
    }
  }

  @override
  void didUpdateWidget(ClientNavigationAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.initialClient != oldWidget.initialClient && widget.initialClient != null) {
      _setNextClient(widget.initialClient!);
    }
    
    if (widget.selectedClient != oldWidget.selectedClient) {
      if (widget.selectedClient != null) {
        _setSelectedClient(widget.selectedClient!);
      } else {
        _clearSelection();
      }
    }
  }

  void _setNextClient(CltData lastAddedClient) {
    final lastIndex = widget.clients.indexWhere((c) => c.rsoc == lastAddedClient.rsoc);
    final nextIndex = (lastIndex + 1) % widget.clients.length;
    final nextClient = widget.clients[nextIndex];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.text = nextClient.rsoc;
        _currentIndex = nextIndex;
        _isNavigationMode = true;
        widget.onClientChanged(nextClient);
        widget.onNextClientSet?.call();
      }
    });
  }
  
  void _setSelectedClient(CltData client) {
    final index = widget.clients.indexWhere((c) => c.rsoc == client.rsoc);
    if (index != -1) {
      _controller.text = client.rsoc;
      _currentIndex = index;
      _userInput = client.rsoc;
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
      _filteredOptions = widget.clients;
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
            ? widget.clients
            : widget.clients
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

  void _selectOption(CltData option) {
    final displayString = option.rsoc;
    _controller.text = displayString;
    _userInput = displayString;
    _currentIndex = widget.clients.indexOf(option);
    setState(() {
      _showSuggestion = false;
      _selectedIndex = -1;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onClientChanged(option);
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

  void _navigateInAllClients(bool next) {
    if (widget.clients.isEmpty) return;

    if (next) {
      _currentIndex = (_currentIndex + 1) % widget.clients.length;
    } else {
      _currentIndex = _currentIndex <= 0 ? widget.clients.length - 1 : _currentIndex - 1;
    }

    final client = widget.clients[_currentIndex];
    _controller.text = client.rsoc;
    _isNavigationMode = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onClientChanged(client);
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
              _navigateInAllClients(false);
            } else {
              _navigateInAutocomplete(false);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_isNavigationMode) {
              _navigateInAllClients(true);
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