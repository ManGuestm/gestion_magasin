import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';

class RegularisationModal extends StatefulWidget {
  const RegularisationModal({super.key});

  @override
  State<RegularisationModal> createState() => _RegularisationModalState();
}

class _RegularisationModalState extends State<RegularisationModal> {
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  String? _selectedRaisonSoc;
  final TextEditingController _libelleController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  String? _selectedAffectation;

  final List<String> _types = ['Client', 'Fournisseur'];
  List<String> _raisonsSociales = [];
  final List<String> _affectations = ['Crédit', 'Débit'];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[200],
      child: Container(
        width: 400,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildForm()),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[300],
        border: Border(bottom: BorderSide(color: Colors.grey[600]!, width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            'REGULARISATION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.red,
              border: Border.all(color: Colors.white),
            ),
            child: const Icon(Icons.close, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormRow('Type', _buildTypeDropdown()),
          const SizedBox(height: 12),
          _buildFormRow('Date', _buildDateField()),
          const SizedBox(height: 12),
          _buildFormRow('Raison Soc', _buildRaisonSocDropdown()),
          const SizedBox(height: 12),
          _buildFormRow('Libellé', _buildLibelleField()),
          const SizedBox(height: 12),
          _buildFormRow('Montant', _buildMontantField()),
          const SizedBox(height: 12),
          _buildFormRow('Affectation', _buildAffectationDropdown()),
        ],
      ),
    );
  }

  Widget _buildFormRow(String label, Widget field) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: field),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedType,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10, color: Colors.black),
        items: _types
            .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedType = value;
            _selectedRaisonSoc = null;
          });
          _loadRaisonsSociales();
        },
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: TextFormField(
        initialValue: DateFormat('dd/MM/yyyy').format(_selectedDate),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildRaisonSocDropdown() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedRaisonSoc,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10, color: Colors.black),
        items: _raisonsSociales
            .map((raison) => DropdownMenuItem(
                  value: raison,
                  child: Text(raison, style: const TextStyle(fontSize: 10)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedRaisonSoc = value;
          });
        },
      ),
    );
  }

  Widget _buildLibelleField() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: TextFormField(
        controller: _libelleController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildMontantField() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: TextFormField(
        controller: _montantController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildAffectationDropdown() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedAffectation,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 10, color: Colors.black),
        items: _affectations
            .map((affectation) => DropdownMenuItem(
                  value: affectation,
                  child: Text(affectation),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedAffectation = value;
          });
        },
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border(top: BorderSide(color: Colors.grey[600]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton('Valider', _valider),
          _buildButton('Annuler', _annuler),
          _buildButton('Fermer', () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      width: 80,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: Colors.black),
        ),
      ),
    );
  }

  Future<void> _loadRaisonsSociales() async {
    if (_selectedType == null) return;

    setState(() => isLoading = true);

    try {
      final db = AppDatabase();
      List<String> results;

      if (_selectedType == 'Client') {
        final clients = await db.getAllClients();
        results = clients.map((c) => c.rsoc).toList();
      } else {
        final fournisseurs = await db.getAllFournisseurs();
        results = fournisseurs.map((f) => f.rsoc).toList();
      }

      setState(() {
        _raisonsSociales = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _valider() async {
    if (_selectedType == null ||
        _selectedRaisonSoc == null ||
        _libelleController.text.isEmpty ||
        _montantController.text.isEmpty ||
        _selectedAffectation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final db = AppDatabase();
      final montant = double.tryParse(_montantController.text) ?? 0.0;

      await db.enregistrerRegularisation(
        type: _selectedType!,
        raisonSociale: _selectedRaisonSoc!,
        date: _selectedDate,
        libelle: _libelleController.text,
        montant: montant,
        affectation: _selectedAffectation!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Régularisation enregistrée avec succès')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _annuler() {
    setState(() {
      _selectedType = null;
      _selectedDate = DateTime.now();
      _selectedRaisonSoc = null;
      _libelleController.clear();
      _montantController.clear();
      _selectedAffectation = null;
    });
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _montantController.dispose();
    super.dispose();
  }
}
