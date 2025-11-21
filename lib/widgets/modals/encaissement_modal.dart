import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../database/database_service.dart';
import '../common/enhanced_autocomplete.dart';

class EncaissementModal extends StatefulWidget {
  const EncaissementModal({super.key});

  @override
  State<EncaissementModal> createState() => _EncaissementModalState();
}

class _EncaissementModalState extends State<EncaissementModal> {
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _libelleController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();

  DateTime _date = DateTime.now();
  String _paymentMethod = 'Espèces';
  List<String> _paymentMethods = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _libelleController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final paymentModes = await _databaseService.database.select(_databaseService.database.mp).get();
      setState(() {
        _paymentMethods = paymentModes.map((mp) => mp.mp).toList();
        if (_paymentMethods.isNotEmpty) {
          _paymentMethod = _paymentMethods.first;
          _paymentMethodController.text = _paymentMethod;
        }
      });
    } catch (e) {
      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _processEncaissement() async {
    final amount = _parseAmount(_amountController.text);
    if (amount <= 0) {
      _showError('Veuillez saisir un montant valide');
      return;
    }

    if (_libelleController.text.trim().isEmpty) {
      _showError('Veuillez saisir un libellé');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ref = 'ENC${DateTime.now().millisecondsSinceEpoch}';

      if (_paymentMethod == 'Espèces') {
        await _databaseService.database.customStatement(
            'INSERT INTO caisse (ref, daty, lib, credit, debit, soldes, type, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              ref,
              _date.toIso8601String(),
              _libelleController.text,
              amount,
              0.0,
              amount,
              'ENCAISSEMENT',
              'MANUEL'
            ]);
      } else {
        await _databaseService.database.customStatement(
            'INSERT INTO banque (ref, daty, lib, credit, debit, soldes, type, verification) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              ref,
              _date.toIso8601String(),
              _libelleController.text,
              amount,
              0.0,
              amount,
              'ENCAISSEMENT',
              'MANUEL'
            ]);
      }

      _showSuccess('Encaissement enregistré avec succès');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('Erreur lors de l\'enregistrement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  double _parseAmount(String text) {
    try {
      return double.parse(text.replaceAll(',', '.').replaceAll(' ', ''));
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'ENCAISSEMENT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                labelText: 'Montant',
                prefixIcon: Icon(Icons.euro),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            EnhancedAutocomplete<String>(
              controller: _paymentMethodController,
              options: _paymentMethods,
              displayStringForOption: (method) => method,
              onSelected: (method) => setState(() => _paymentMethod = method),
              decoration: const InputDecoration(
                labelText: 'Mode de paiement',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _date = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(
                labelText: 'Libellé',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processEncaissement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENREGISTRER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
