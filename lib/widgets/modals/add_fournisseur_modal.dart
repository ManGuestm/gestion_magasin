import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class AddFournisseurModal extends StatefulWidget {
  final Frn? fournisseur;
  final String? nomFournisseur;

  const AddFournisseurModal({super.key, this.fournisseur, this.nomFournisseur});

  @override
  State<AddFournisseurModal> createState() => _AddFournisseurModalState();
}

class _AddFournisseurModalState extends State<AddFournisseurModal> {
  final _formKey = GlobalKey<FormState>();
  final _rsocController = TextEditingController();
  final _adrController = TextEditingController();
  final _capitalController = TextEditingController();
  final _rcsController = TextEditingController();
  final _nifController = TextEditingController();
  final _statController = TextEditingController();
  final _telController = TextEditingController();
  final _portController = TextEditingController();
  final _emailController = TextEditingController();
  final _siteController = TextEditingController();
  final _faxController = TextEditingController();
  final _telexController = TextEditingController();

  bool get _isEditing => widget.fournisseur != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadFournisseurData();
    } else if (widget.nomFournisseur != null) {
      _rsocController.text = widget.nomFournisseur!;
    }
  }

  void _loadFournisseurData() {
    final fournisseur = widget.fournisseur!;
    _rsocController.text = fournisseur.rsoc;
    _adrController.text = fournisseur.adr ?? '';
    _capitalController.text = fournisseur.capital?.toString() ?? '';
    _rcsController.text = fournisseur.rcs ?? '';
    _nifController.text = fournisseur.nif ?? '';
    _statController.text = fournisseur.stat ?? '';
    _telController.text = fournisseur.tel ?? '';
    _portController.text = fournisseur.port ?? '';
    _emailController.text = fournisseur.email ?? '';
    _siteController.text = fournisseur.site ?? '';
    _faxController.text = fournisseur.fax ?? '';
    _telexController.text = fournisseur.telex ?? '';
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
        widget.fournisseur == null ? 'NOUVEAU ...' : 'MODIFIER ...',
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
                      _buildTextAreaField('Siège Social', _adrController),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLabeledField('Capital', _capitalController),
                      const SizedBox(height: 8),
                      _buildLabeledField('RCS', _rcsController),
                      const SizedBox(height: 8),
                      _buildLabeledField('N.I.F', _nifController),
                      const SizedBox(height: 8),
                      _buildLabeledField('STAT', _statController),
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
                    Expanded(child: _buildLabeledField('Fax', _faxController)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildLabeledField('Portables', _portController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLabeledField('Telex', _telexController)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLabeledField('Email', _emailController),
                const SizedBox(height: 8),
                _buildLabeledField('Site internet', _siteController),
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

  Widget _buildTextAreaField(String label, TextEditingController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          width: 200,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 11),
            maxLines: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              isDense: true,
            ),
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
              onPressed: _saveFournisseur,
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

  Future<void> _saveFournisseur() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final companion = FrnsCompanion(
        rsoc: drift.Value(_rsocController.text),
        adr: drift.Value(_adrController.text.isEmpty ? null : _adrController.text),
        capital: drift.Value(double.tryParse(_capitalController.text)),
        rcs: drift.Value(_rcsController.text.isEmpty ? null : _rcsController.text),
        nif: drift.Value(_nifController.text.isEmpty ? null : _nifController.text),
        stat: drift.Value(_statController.text.isEmpty ? null : _statController.text),
        tel: drift.Value(_telController.text.isEmpty ? null : _telController.text),
        port: drift.Value(_portController.text.isEmpty ? null : _portController.text),
        email: drift.Value(_emailController.text.isEmpty ? null : _emailController.text),
        site: drift.Value(_siteController.text.isEmpty ? null : _siteController.text),
        fax: drift.Value(_faxController.text.isEmpty ? null : _faxController.text),
        telex: drift.Value(_telexController.text.isEmpty ? null : _telexController.text),
      );

      if (widget.fournisseur == null) {
        await DatabaseService().database.insertFournisseur(companion);
      } else {
        await DatabaseService().database.updateFournisseur(widget.fournisseur!.rsoc, companion);
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
    _capitalController.dispose();
    _rcsController.dispose();
    _nifController.dispose();
    _statController.dispose();
    _telController.dispose();
    _portController.dispose();
    _emailController.dispose();
    _siteController.dispose();
    _faxController.dispose();
    _telexController.dispose();
    super.dispose();
  }
}
