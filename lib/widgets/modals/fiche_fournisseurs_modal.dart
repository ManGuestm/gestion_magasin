import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../common/base_modal.dart';
import '../common/data_table_widget.dart';

class FicheFournisseursModal extends StatefulWidget {
  const FicheFournisseursModal({super.key});

  @override
  State<FicheFournisseursModal> createState() => _FicheFournisseursModalState();
}

class _FicheFournisseursModalState extends State<FicheFournisseursModal> {
  List<Frn> _fournisseurs = [];
  List<Frn> _filteredFournisseurs = [];
  bool _isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
  }

  Future<void> _loadFournisseurs() async {
    setState(() => _isLoading = true);
    try {
      final fournisseurs = await DatabaseService().database.getAllFournisseurs();
      setState(() {
        _fournisseurs = fournisseurs;
        _filteredFournisseurs = fournisseurs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterFournisseurs(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        _filteredFournisseurs = _fournisseurs;
      } else {
        _filteredFournisseurs = _fournisseurs
            .where((f) =>
                f.rsoc.toLowerCase().contains(query.toLowerCase()) ||
                (f.nif?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                (f.tel?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Fiche Fournisseurs',
      width: 1000,
      height: 700,
      content: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher un fournisseur',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterFournisseurs,
            ),
          ),

          // Tableau des fournisseurs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DataTableWidget<Frn>(
                    headers: const [
                      'Raison Sociale',
                      'Adresse',
                      'Téléphone',
                      'Email',
                      'NIF',
                      'Solde',
                      'Dernière Op.',
                    ],
                    items: _filteredFournisseurs,
                    rowBuilder: (fournisseur, isSelected) => [
                      Expanded(
                          child: Text(fournisseur.rsoc,
                              style:
                                  TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black))),
                      Expanded(
                          child: Text(fournisseur.adr ?? '',
                              style:
                                  TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black))),
                      Expanded(
                          child: Text(fournisseur.tel ?? '',
                              style:
                                  TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black))),
                      Expanded(
                          child: Text(fournisseur.email ?? '',
                              style:
                                  TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black))),
                      Expanded(
                          child: Text(fournisseur.nif ?? '',
                              style:
                                  TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black))),
                      Expanded(
                          child: Text('${_formatNumber(fournisseur.soldes ?? 0)} Ar',
                              style:
                                  TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black))),
                      Expanded(
                          child: Text(
                              fournisseur.datedernop != null
                                  ? DateFormat('dd/MM/yyyy').format(fournisseur.datedernop!)
                                  : '',
                              style:
                                  TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black))),
                    ],
                    onItemSelected: (fournisseur) => _showFournisseurDetails(fournisseur),
                  ),
          ),

          // Résumé
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: const Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${_filteredFournisseurs.length} fournisseur(s)'),
                Text('Solde total: ${_formatNumber(_calculateTotalSolde())} Ar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFournisseurDetails(Frn fournisseur) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${fournisseur.rsoc}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Raison sociale:', fournisseur.rsoc),
              _buildDetailRow('Adresse:', fournisseur.adr ?? ''),
              _buildDetailRow('Capital:', '${_formatNumber(fournisseur.capital ?? 0)} Ar'),
              _buildDetailRow('RCS:', fournisseur.rcs ?? ''),
              _buildDetailRow('NIF:', fournisseur.nif ?? ''),
              _buildDetailRow('STAT:', fournisseur.stat ?? ''),
              _buildDetailRow('Téléphone:', fournisseur.tel ?? ''),
              _buildDetailRow('Portable:', fournisseur.port ?? ''),
              _buildDetailRow('Email:', fournisseur.email ?? ''),
              _buildDetailRow('Site web:', fournisseur.site ?? ''),
              _buildDetailRow('Fax:', fournisseur.fax ?? ''),
              _buildDetailRow('Télex:', fournisseur.telex ?? ''),
              _buildDetailRow('Solde:', '${_formatNumber(fournisseur.soldes ?? 0)} Ar'),
              _buildDetailRow('Délai paiement:', '${fournisseur.delai ?? 0} jours'),
              _buildDetailRow(
                  'Dernière opération:',
                  fournisseur.datedernop != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(fournisseur.datedernop!)
                      : 'Aucune'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  double _calculateTotalSolde() {
    return _filteredFournisseurs.fold(0.0, (sum, f) => sum + (f.soldes ?? 0));
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}
