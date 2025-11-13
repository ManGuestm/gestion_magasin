import 'package:flutter/material.dart';

import '../../database/database_service.dart';
import '../../utils/number_utils.dart';

class BilanCompteResultatModal extends StatefulWidget {
  const BilanCompteResultatModal({super.key});

  @override
  State<BilanCompteResultatModal> createState() => _BilanCompteResultatModalState();
}

class _BilanCompteResultatModalState extends State<BilanCompteResultatModal> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  String _selectedType = 'Bilan';

  // Données financières
  double _chiffreAffaires = 0;
  double _achats = 0;
  double _charges = 0;
  double _immobilisations = 0;
  double _stocks = 0;
  double _creancesClients = 0;
  double _tresorerie = 0;
  double _detteFournisseurs = 0;

  @override
  void initState() {
    super.initState();
    _loadDonneesFinancieres();
  }

  Future<void> _loadDonneesFinancieres() async {
    try {
      final ventes = await _databaseService.database.getAllVentes();
      final achats = await _databaseService.database.getAllAchats();
      final clients = await _databaseService.database.getAllClients();
      final fournisseurs = await _databaseService.database.getAllFournisseurs();
      final articles = await _databaseService.database.getAllArticles();
      final caisses = await _databaseService.database.getAllCaisses();
      final banques = await _databaseService.database.getAllBanques();
      final autresComptes = await _databaseService.database.getAllAutrescomptes();

      // Utiliser une requête SQL directe pour les immobilisations
      final database = _databaseService.database;
      final immobilisations = await database.customSelect('SELECT * FROM emb').get();

      setState(() {
        _chiffreAffaires = ventes.fold(0.0, (sum, v) => sum + (v.totalttc ?? 0));
        _achats = achats.fold(0.0, (sum, a) => sum + (a.totalttc ?? 0));
        _charges = autresComptes.fold(0.0, (sum, c) => sum + (c.sortie ?? 0));
        _immobilisations = immobilisations.fold(0.0, (sum, i) => sum + ((i.data['vo'] as double?) ?? 0));
        _stocks = articles.fold(0.0, (sum, a) => sum + ((a.stocksu1 ?? 0) * (a.cmup ?? 0)));
        _creancesClients = clients.fold(0.0, (sum, c) => sum + (c.soldes ?? 0));
        _detteFournisseurs = fournisseurs.fold(0.0, (sum, f) => sum + (f.soldes ?? 0));
        _tresorerie = caisses.fold(0.0, (sum, c) => sum + ((c.credit ?? 0) - (c.debit ?? 0))) +
            banques.fold(0.0, (sum, b) => sum + ((b.credit ?? 0) - (b.debit ?? 0)));
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

  Widget _buildBilan() {
    double totalActif = _immobilisations + _stocks + _creancesClients + _tresorerie;
    double totalPassif = _detteFournisseurs + (totalActif - _detteFournisseurs); // Capitaux propres

    return Row(
      children: [
        // ACTIF
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Text('ACTIF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildLigneBilan('Immobilisations', _immobilisations),
                        _buildLigneBilan('Stocks', _stocks),
                        _buildLigneBilan('Créances clients', _creancesClients),
                        _buildLigneBilan('Trésorerie', _tresorerie),
                        const Divider(),
                        _buildLigneBilan('TOTAL ACTIF', totalActif, isTotal: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // PASSIF
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Text('PASSIF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildLigneBilan('Capitaux propres', totalActif - _detteFournisseurs),
                        _buildLigneBilan('Dettes fournisseurs', _detteFournisseurs),
                        const Divider(),
                        _buildLigneBilan('TOTAL PASSIF', totalPassif, isTotal: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompteResultat() {
    double resultatNet = _chiffreAffaires - _achats - _charges;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Center(
              child: Text('COMPTE DE RÉSULTAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLigneBilan('Chiffre d\'affaires', _chiffreAffaires),
                  _buildLigneBilan('Achats', -_achats),
                  const Divider(),
                  _buildLigneBilan('Marge commerciale', _chiffreAffaires - _achats),
                  _buildLigneBilan('Charges', -_charges),
                  const Divider(),
                  _buildLigneBilan('RÉSULTAT NET', resultatNet, isTotal: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLigneBilan(String libelle, double montant, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            libelle,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          Text(
            NumberUtils.formatNumber(montant),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
              color: montant < 0 ? Colors.red : (isTotal ? Colors.blue : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bilan / Compte de Résultat',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Type de rapport: '),
                  DropdownButton<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'Bilan', child: Text('Bilan')),
                      DropdownMenuItem(value: 'Compte de Résultat', child: Text('Compte de Résultat')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? 'Bilan';
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedType == 'Bilan'
                      ? _buildBilan()
                      : _buildCompteResultat(),
            ),
          ],
        ),
      ),
    );
  }
}
