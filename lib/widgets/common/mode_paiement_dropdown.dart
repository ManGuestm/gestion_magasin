import 'package:flutter/material.dart';

import '../../services/mode_paiement_service.dart';

class ModePaiementDropdown extends StatefulWidget {
  final String? selectedMode;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final bool showCreditMode;
  final bool tousDepots;

  const ModePaiementDropdown({
    super.key,
    this.selectedMode,
    required this.onChanged,
    this.enabled = true,
    this.showCreditMode = true,
    this.tousDepots = true,
  });

  @override
  State<ModePaiementDropdown> createState() => _ModePaiementDropdownState();
}

class _ModePaiementDropdownState extends State<ModePaiementDropdown> {
  List<String> _modesPaiement = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModesPaiement();
  }

  Future<void> _loadModesPaiement() async {
    try {
      final modes = await ModePaiementService().getAllModesPaiement();
      if (mounted) {
        setState(() {
          _modesPaiement = modes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modesPaiement = ['Espèces', 'A crédit', 'Mobile Money']; // Fallback
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 120,
        height: 20,
        child:
            Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1))),
      );
    }

    final availableModes = _modesPaiement.where((mode) {
      if (mode != 'A crédit') return true;
      if (!widget.tousDepots) return false;
      return widget.showCreditMode;
    }).toList();

    final validSelectedMode = availableModes.contains(widget.selectedMode)
        ? widget.selectedMode
        : (availableModes.isNotEmpty ? availableModes.first : null);

    // Notify parent if selected mode was automatically changed
    if (validSelectedMode != widget.selectedMode && validSelectedMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(validSelectedMode);
      });
    }

    return Container(
      width: 120,
      height: 20,
      decoration: BoxDecoration(
        color: widget.enabled ? Colors.white : Colors.grey[200],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: validSelectedMode,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 11, color: Colors.black),
        items: availableModes
            .map((mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode),
                ))
            .toList(),
        onChanged: widget.enabled ? widget.onChanged : null,
      ),
    );
  }
}
