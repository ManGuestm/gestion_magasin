import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class AddClientModal extends StatefulWidget {
  final CltData? client;

  const AddClientModal({super.key, this.client});

  @override
  State<AddClientModal> createState() => _AddClientModalState();
}

class _AddClientModalState extends State<AddClientModal> {
  final _formKey = GlobalKey<FormState>();
  final _rsocController = TextEditingController();
  final _adrController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _nifController = TextEditingController();
  final _rcsController = TextEditingController();
  final _soldesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _rsocController.text = widget.client!.rsoc;
      _adrController.text = widget.client!.adr ?? '';
      _telController.text = widget.client!.tel ?? '';
      _emailController.text = widget.client!.email ?? '';
      _nifController.text = widget.client!.nif ?? '';
      _rcsController.text = widget.client!.rcs ?? '';
      _soldesController.text = widget.client!.soldes?.toString() ?? '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Container(
          width: 700,
          height: 450,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _buildIdentificationSection(),
                          const SizedBox(height: 8),
                          _buildCoordonneeSection(),
                          const SizedBox(height: 8),
                          _buildComptesSection(),
                        ],
                      ),
                    ),
                  ),
                ),
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
        color: Colors.blue[100],
        border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
      ),
      child: Text(
        widget.client == null ? 'NOUVEAU ...' : 'MODIFIER ...',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIdentificationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: const Text(
              'IDENTIFICATION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLabeledField('Raison Social', _rsocController, required: true),
                      const SizedBox(height: 8),
                      _buildLabeledField('Siège Social', _adrController),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabeledField('Capital', TextEditingController()),
                      const SizedBox(height: 8),
                      _buildLabeledField('RCS', _rcsController),
                      const SizedBox(height: 8),
                      _buildLabeledField('N.I.F', _nifController),
                      const SizedBox(height: 8),
                      _buildLabeledField('STAT', TextEditingController()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordonneeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: const Text(
              'COORDONNEES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildLabeledField('Telephone', _telController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('Fax', TextEditingController())),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildLabeledField('Portables', TextEditingController())),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('Telex', TextEditingController())),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLabeledField('Email', _emailController),
                const SizedBox(height: 8),
                _buildLabeledField('Site internet', TextEditingController()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComptesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              border: Border(bottom: BorderSide(color: Colors.grey[400]!)),
            ),
            child: const Text(
              'COMPTES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildLabeledField('Commercial', TextEditingController(), width: 120),
                    const SizedBox(width: 8),
                    _buildLabeledField('Taux Remise(%)', TextEditingController(), width: 80),
                    const SizedBox(width: 8),
                    _buildLabeledField('Plafonnement', TextEditingController(), width: 120),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLabeledField('Catégorie', TextEditingController(), width: 120),
                    const SizedBox(width: 8),
                    _buildLabeledField('Plafonnement BL', TextEditingController(), width: 120),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
      {bool required = false, double? width}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: width ?? 200,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              isDense: true,
            ),
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(color: Colors.grey[400]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.orange[200],
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: TextButton(
              onPressed: _saveClient,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Valider',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.orange[200],
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

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = CltCompanion(
        rsoc: drift.Value(_rsocController.text),
        adr: drift.Value(_adrController.text.isEmpty ? null : _adrController.text),
        tel: drift.Value(_telController.text.isEmpty ? null : _telController.text),
        email: drift.Value(_emailController.text.isEmpty ? null : _emailController.text),
        nif: drift.Value(_nifController.text.isEmpty ? null : _nifController.text),
        rcs: drift.Value(_rcsController.text.isEmpty ? null : _rcsController.text),
        soldes: drift.Value(double.tryParse(_soldesController.text) ?? 0.0),
      );

      if (widget.client == null) {
        await DatabaseService().database.insertClient(companion);
      } else {
        await DatabaseService().database.updateClient(widget.client!.rsoc, companion);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _rsocController.dispose();
    _adrController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _nifController.dispose();
    _rcsController.dispose();
    _soldesController.dispose();
    super.dispose();
  }
}
