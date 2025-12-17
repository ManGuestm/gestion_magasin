import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
            .where(
              (f) =>
                  f.rsoc.toLowerCase().contains(query.toLowerCase()) ||
                  (f.nif?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                  (f.tel?.toLowerCase().contains(query.toLowerCase()) ?? false),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1200,
        height: 800,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildModernHeader(),
            _buildSearchSection(),
            _buildStatsCards(),
            Expanded(child: _buildFournisseursTable()),
            _buildFooterSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiche Fournisseurs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Gestion et consultation des fournisseurs',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadFournisseurs,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue[600], size: 20),
              const SizedBox(width: 12),
              const Text('Rechercher:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Nom, NIF, téléphone...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    onChanged: _filterFournisseurs,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Fournisseurs',
              _filteredFournisseurs.length.toString(),
              Icons.business,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Solde Total',
              '${_formatNumber(_calculateTotalSolde())} Ar',
              Icons.account_balance_wallet,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFournisseursTable() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des fournisseurs...'),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: DataTableWidget<Frn>(
        headers: const ['Raison Sociale', 'Adresse', 'Téléphone', 'Email', 'NIF', 'Solde', 'Dernière Op.'],
        items: _filteredFournisseurs,
        rowBuilder: (fournisseur, isSelected) => [
          Expanded(
            child: Text(
              fournisseur.rsoc,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              fournisseur.adr ?? '',
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              fournisseur.tel ?? '',
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              fournisseur.email ?? '',
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              fournisseur.nif ?? '',
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              '${_formatNumber(fournisseur.soldes ?? 0)} Ar',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              fournisseur.datedernop != null ? DateFormat('dd/MM/yyyy').format(fournisseur.datedernop!) : '',
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87),
            ),
          ),
        ],
        onItemSelected: (fournisseur) => _showFournisseurDetails(fournisseur),
      ),
    );
  }

  Widget _buildFooterSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${_filteredFournisseurs.length} fournisseur(s)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            'Solde total: ${_formatNumber(_calculateTotalSolde())} Ar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700]),
          ),
        ],
      ),
    );
  }

  void _showFournisseurDetails(Frn fournisseur) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[700]!]),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Détails - ${fournisseur.rsoc}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                          : 'Aucune',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }
}
