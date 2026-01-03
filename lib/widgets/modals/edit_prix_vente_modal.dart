import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/number_utils.dart';

class EditPrixVenteModal extends StatefulWidget {
  final Article article;

  const EditPrixVenteModal({super.key, required this.article});

  @override
  State<EditPrixVenteModal> createState() => _EditPrixVenteModalState();
}

class _EditPrixVenteModalState extends State<EditPrixVenteModal> {
  final _formKey = GlobalKey<FormState>();
  final _pvu1Controller = TextEditingController();
  final _pvu2Controller = TextEditingController();
  final _pvu3Controller = TextEditingController();
  final _pvu1Focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _pvu1Controller.text = NumberUtils.formatNumber(widget.article.pvu1 ?? 0);
    _pvu2Controller.text = NumberUtils.formatNumber(widget.article.pvu2 ?? 0);
    _pvu3Controller.text = NumberUtils.formatNumber(widget.article.pvu3 ?? 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_pvu1Focus);
      _pvu1Controller.selection = TextSelection(baseOffset: 0, extentOffset: _pvu1Controller.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modifier Prix de Vente',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Article: ${widget.article.designation}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (widget.article.u1?.isNotEmpty == true)
                _buildPrixField('Prix ${widget.article.u1}', _pvu1Controller, _pvu1Focus),
              if (widget.article.u2?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildPrixField('Prix ${widget.article.u2}', _pvu2Controller),
              ],
              if (widget.article.u3?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildPrixField('Prix ${widget.article.u3}', _pvu3Controller),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savePrix,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrixField(String label, TextEditingController controller, [FocusNode? focusNode]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixText: 'Ar',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            if (NumberUtils.parseFormattedNumber(value) < 0) return 'Prix invalide';
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _savePrix() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = ArticlesCompanion(
        designation: drift.Value(widget.article.designation),
        pvu1: drift.Value(NumberUtils.parseFormattedNumber(_pvu1Controller.text)),
        pvu2: drift.Value(NumberUtils.parseFormattedNumber(_pvu2Controller.text)),
        pvu3: drift.Value(NumberUtils.parseFormattedNumber(_pvu3Controller.text)),
      );

      await DatabaseService().database.updateArticle(companion);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  void dispose() {
    _pvu1Focus.dispose();
    _pvu1Controller.dispose();
    _pvu2Controller.dispose();
    _pvu3Controller.dispose();
    super.dispose();
  }
}
