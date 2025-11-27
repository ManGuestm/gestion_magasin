import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class AddPlanCompteModal extends StatefulWidget {
  final CaData? compte;

  const AddPlanCompteModal({super.key, this.compte});

  @override
  State<AddPlanCompteModal> createState() => _AddPlanCompteModalState();
}

class _AddPlanCompteModalState extends State<AddPlanCompteModal> with TabNavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _intituleController = TextEditingController();
  String _selectedClasse = 'Charges';

  final List<String> _classes = ['Charges', 'Produits', 'Actifs', 'Passifs'];

  @override
  void initState() {
    super.initState();
    if (widget.compte != null) {
      _codeController.text = widget.compte!.code;
      _intituleController.text = widget.compte!.intitule ?? '';
      _selectedClasse = widget.compte!.compte ?? 'Charges';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: Container(
          width: 450,
          height: 230,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildForm()),
              _buildButtons(),
            ],
          ),
        ),
      ),
    ),);
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Text(
        widget.compte == null ? 'CREER ...' : 'MODIFIER ...',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue[100],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildFormField('Code', _codeController),
            const SizedBox(height: 8),
            _buildFormField('Intitulé', _intituleController),
            const SizedBox(height: 8),
            _buildClasseDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                isDense: true,
              ),
              validator: (value) => value?.isEmpty == true ? 'Requis' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClasseDropdown() {
    return Row(
      children: [
        const SizedBox(
          width: 80,
          child: Text(
            'Classe',
            style: TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedClasse,
              style: const TextStyle(fontSize: 11, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                isDense: true,
              ),
              items: _classes.map((String classe) {
                return DropdownMenuItem<String>(
                  value: classe,
                  child: Text(classe),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedClasse = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: TextButton(
              onPressed: _saveCompte,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCompte() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = CaCompanion(
        code: drift.Value(_codeController.text),
        intitule: drift.Value(_intituleController.text.isEmpty ? null : _intituleController.text),
        compte: drift.Value(_selectedClasse),
        soldes: const drift.Value(0.0),
        soldesa: const drift.Value(0.0),
      );

      if (widget.compte == null) {
        await DatabaseService().database.insertCa(companion);
      } else {
        await DatabaseService().database.updateCa(companion);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _intituleController.dispose();
    super.dispose();
  }
}
