import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class AddFournisseurModal extends StatefulWidget {
  final Frn? fournisseur;

  const AddFournisseurModal({super.key, this.fournisseur});

  @override
  State<AddFournisseurModal> createState() => _AddFournisseurModalState();
}

class _AddFournisseurModalState extends State<AddFournisseurModal> {
  final _formKey = GlobalKey<FormState>();

  // Controllers pour les champs
  final _raisonSocialeController = TextEditingController();
  final _siegeSocialController = TextEditingController();
  final _capitalController = TextEditingController();
  final _rcsController = TextEditingController();
  final _nifController = TextEditingController();
  final _statController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _faxController = TextEditingController();
  final _portablesController = TextEditingController();
  final _telexController = TextEditingController();
  final _emailController = TextEditingController();
  final _siteInternetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.fournisseur != null) {
      _loadFournisseurData();
    }
  }

  void _loadFournisseurData() {
    final fournisseur = widget.fournisseur!;
    _raisonSocialeController.text = fournisseur.rsoc;
    _siegeSocialController.text = fournisseur.adr ?? '';
    _capitalController.text = fournisseur.capital?.toString() ?? '';
    _rcsController.text = fournisseur.rcs ?? '';
    _nifController.text = fournisseur.nif ?? '';
    _statController.text = fournisseur.stat ?? '';
    _telephoneController.text = fournisseur.tel ?? '';
    _faxController.text = fournisseur.fax ?? '';
    _portablesController.text = fournisseur.port ?? '';
    _telexController.text = fournisseur.telex ?? '';
    _emailController.text = fournisseur.email ?? '';
    _siteInternetController.text = fournisseur.site ?? '';
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
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIdentificationSection(),
                          const SizedBox(height: 16),
                          _buildCoordonneesSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildButtons(),
            ],
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Text(
        widget.fournisseur == null ? 'CREER ...' : 'MODIFIER ...',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIdentificationSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        color: Colors.blue[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IDENTIFICATION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildTextField('Raison Social', _raisonSocialeController, required: true),
                    const SizedBox(height: 8),
                    _buildTextField('Siège Social', _siegeSocialController, multiline: true),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildTextField('Capital', _capitalController),
                    const SizedBox(height: 8),
                    _buildTextField('RCS', _rcsController),
                    const SizedBox(height: 8),
                    _buildTextField('N.I.F', _nifController),
                    const SizedBox(height: 8),
                    _buildTextField('STAT', _statController),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordonneesSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        color: Colors.blue[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COORDONNEES',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTextField('Telephone', _telephoneController),
                    const SizedBox(height: 8),
                    _buildTextField('Portables', _portablesController),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildTextField('Fax', _faxController),
                    const SizedBox(height: 8),
                    _buildTextField('Telex', _telexController),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField('Email', _emailController),
          const SizedBox(height: 8),
          _buildTextField('Site internet', _siteInternetController),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool required = false, bool multiline = false}) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Expanded(
          child: Container(
            height: multiline ? 60 : 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              color: Colors.white,
            ),
            child: TextFormField(
              controller: controller,
              maxLines: multiline ? 3 : 1,
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                isDense: true,
              ),
              validator: required
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ce champ est requis';
                      }
                      return null;
                    }
                  : null,
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
        color: Colors.blue[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final fournisseurData = FrnsCompanion(
        rsoc: drift.Value(_raisonSocialeController.text),
        adr: drift.Value(_siegeSocialController.text.isEmpty ? null : _siegeSocialController.text),
        capital:
            drift.Value(_capitalController.text.isEmpty ? null : double.tryParse(_capitalController.text)),
        rcs: drift.Value(_rcsController.text.isEmpty ? null : _rcsController.text),
        nif: drift.Value(_nifController.text.isEmpty ? null : _nifController.text),
        stat: drift.Value(_statController.text.isEmpty ? null : _statController.text),
        tel: drift.Value(_telephoneController.text.isEmpty ? null : _telephoneController.text),
        fax: drift.Value(_faxController.text.isEmpty ? null : _faxController.text),
        port: drift.Value(_portablesController.text.isEmpty ? null : _portablesController.text),
        telex: drift.Value(_telexController.text.isEmpty ? null : _telexController.text),
        email: drift.Value(_emailController.text.isEmpty ? null : _emailController.text),
        site: drift.Value(_siteInternetController.text.isEmpty ? null : _siteInternetController.text),
        soldes: const drift.Value(0.0),
        action: const drift.Value('A'),
      );

      if (widget.fournisseur == null) {
        await DatabaseService().database.insertFournisseur(fournisseurData);
      } else {
        await DatabaseService().database.updateFournisseur(widget.fournisseur!.rsoc, fournisseurData);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _raisonSocialeController.dispose();
    _siegeSocialController.dispose();
    _capitalController.dispose();
    _rcsController.dispose();
    _nifController.dispose();
    _statController.dispose();
    _telephoneController.dispose();
    _faxController.dispose();
    _portablesController.dispose();
    _telexController.dispose();
    _emailController.dispose();
    _siteInternetController.dispose();
    super.dispose();
  }
}
