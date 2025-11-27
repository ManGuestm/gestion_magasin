import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/tab_navigation_widget.dart';

class AddBanqueModal extends StatefulWidget {
  final BqData? banque;

  const AddBanqueModal({super.key, this.banque});

  @override
  State<AddBanqueModal> createState() => _AddBanqueModalState();
}

class _AddBanqueModalState extends State<AddBanqueModal> with TabNavigationMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _intituleController = TextEditingController();
  final _ncompteController = TextEditingController();

  late final FocusNode _codeFocusNode;
  late final FocusNode _intituleFocusNode;
  late final FocusNode _ncompteFocusNode;

  @override
  void initState() {
    super.initState();

    // Initialize focus nodes with tab navigation
    _codeFocusNode = createFocusNode();
    _intituleFocusNode = createFocusNode();
    _ncompteFocusNode = createFocusNode();

    if (widget.banque != null) {
      _codeController.text = widget.banque!.code;
      _intituleController.text = widget.banque!.intitule ?? '';
      _ncompteController.text = widget.banque!.nCompte ?? '';
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
            width: 400,
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
      ),
    );
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
        widget.banque == null ? 'CREER ...' : 'MODIFIER ...',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildFormField('Code', _codeController),
            const SizedBox(height: 8),
            _buildFormField('Intitulé', _intituleController),
            const SizedBox(height: 8),
            _buildFormField('N° de compte', _ncompteController),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller) {
    FocusNode focusNode;
    if (controller == _codeController) {
      focusNode = _codeFocusNode;
    } else if (controller == _intituleController) {
      focusNode = _intituleFocusNode;
    } else {
      focusNode = _ncompteFocusNode;
    }

    return Row(
      children: [
        SizedBox(
          width: 100,
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
              focusNode: focusNode,
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                isDense: true,
              ),
              validator: label == 'Code' || label == 'Intitulé'
                  ? (value) => value?.isEmpty == true ? 'Requis' : null
                  : null,
              onTap: () => updateFocusIndex(focusNode),
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
        color: Colors.grey[200],
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
              onPressed: _saveBanque,
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

  Future<void> _saveBanque() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = BqCompanion(
        code: drift.Value(_codeController.text),
        intitule: drift.Value(_intituleController.text.isEmpty ? null : _intituleController.text),
        nCompte: drift.Value(_ncompteController.text.isEmpty ? null : _ncompteController.text),
        soldes: const drift.Value(0.0),
      );

      if (widget.banque == null) {
        await DatabaseService().database.insertBq(companion);
      } else {
        await DatabaseService().database.updateBq(companion);
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
    _ncompteController.dispose();
    super.dispose();
  }
}
