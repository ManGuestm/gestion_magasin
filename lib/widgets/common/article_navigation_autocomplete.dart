import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database.dart';

class ArticleNavigationAutocomplete extends StatefulWidget {
  final List<Article> articles;
  final Article? initialArticle;
  final Function(Article?) onArticleChanged;
  final FocusNode focusNode;
  final bool enabled;
  final String hintText;
  final InputDecoration? decoration;
  final TextStyle? style;
  final VoidCallback? onTabPressed;
  final VoidCallback? onShiftTabPressed;
  final VoidCallback? onNextArticleSet;
  final Article? selectedArticle; // Nouvel paramètre pour synchronisation

  const ArticleNavigationAutocomplete({
    super.key,
    required this.articles,
    this.initialArticle,
    required this.onArticleChanged,
    required this.focusNode,
    this.enabled = true,
    this.hintText = '',
    this.decoration,
    this.style,
    this.onTabPressed,
    this.onShiftTabPressed,
    this.onNextArticleSet,
    this.selectedArticle, // Nouvel paramètre
  });

  @override
  State<ArticleNavigationAutocomplete> createState() => _ArticleNavigationAutocompleteState();
}

class _ArticleNavigationAutocompleteState extends State<ArticleNavigationAutocomplete> {
  late TextEditingController _controller;
  List<Article> _filteredOptions = [];
  int _selectedIndex = -1;
  int _currentIndex = -1;
  String _userInput = '';
  bool _showSuggestion = false;
  bool _isNavigationMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filteredOptions = widget.articles;
    
    _controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
    
    // Set initial article if provided (next article after last added)
    if (widget.initialArticle != null) {
      _setNextArticle(widget.initialArticle!);
    }
  }

  @override
  void didUpdateWidget(ArticleNavigationAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update if initial article changed
    if (widget.initialArticle != oldWidget.initialArticle && widget.initialArticle != null) {
      _setNextArticle(widget.initialArticle!);
    }
    
    // Update if selected article changed (for line modification)
    if (widget.selectedArticle != oldWidget.selectedArticle) {
      if (widget.selectedArticle != null) {
        _setSelectedArticle(widget.selectedArticle!);
      } else {
        _clearSelection();
      }
    }
  }

  void _setNextArticle(Article lastAddedArticle) {
    final lastIndex = widget.articles.indexWhere((a) => a.designation == lastAddedArticle.designation);
    final nextIndex = (lastIndex + 1) % widget.articles.length;
    final nextArticle = widget.articles[nextIndex];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.text = nextArticle.designation;
        _currentIndex = nextIndex;
        _isNavigationMode = true;
        widget.onArticleChanged(nextArticle);
        widget.onNextArticleSet?.call();
      }
    });
  }
  
  void _setSelectedArticle(Article article) {
    final index = widget.articles.indexWhere((a) => a.designation == article.designation);
    if (index != -1) {
      _controller.text = article.designation;
      _currentIndex = index;
      _userInput = article.designation;
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
      _filteredOptions = widget.articles;
    });
  }

  void _onTextChanged() {
    final text = _controller.text;
    final selection = _controller.selection;

    // If user is typing (not in navigation mode), switch to autocomplete mode
    if (selection.baseOffset == selection.extentOffset || text.length < _userInput.length) {
      _userInput = text;
      _isNavigationMode = false;
    }

    if (mounted && !_isNavigationMode) {
      setState(() {
        _filteredOptions = _userInput.isEmpty
            ? widget.articles
            : widget.articles
                .where((option) =>
                    option.designation.toLowerCase().startsWith(_userInput.toLowerCase()))
                .toList();

        _selectedIndex = _filteredOptions.isNotEmpty ? 0 : -1;
        _showSuggestion = _userInput.isNotEmpty && _filteredOptions.isNotEmpty;

        // Auto-complete first match when user types
        if (_showSuggestion &&
            widget.focusNode.hasFocus &&
            selection.baseOffset == selection.extentOffset &&
            _userInput.isNotEmpty) {
          final firstMatch = _filteredOptions[0].designation;
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

  void _selectOption(Article option) {
    final displayString = option.designation;
    _controller.text = displayString;
    _userInput = displayString;
    _currentIndex = widget.articles.indexOf(option);
    setState(() {
      _showSuggestion = false;
      _selectedIndex = -1;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onArticleChanged(option);
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
    final displayString = selectedOption.designation;

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

  void _navigateInAllArticles(bool next) {
    if (widget.articles.isEmpty) return;

    if (next) {
      _currentIndex = (_currentIndex + 1) % widget.articles.length;
    } else {
      _currentIndex = _currentIndex <= 0 ? widget.articles.length - 1 : _currentIndex - 1;
    }

    final article = widget.articles[_currentIndex];
    _controller.text = article.designation;
    _isNavigationMode = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onArticleChanged(article);
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
              _navigateInAllArticles(false);
            } else {
              _navigateInAutocomplete(false);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_isNavigationMode) {
              _navigateInAllArticles(true);
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

            // If in autocomplete mode, select the suggestion first
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