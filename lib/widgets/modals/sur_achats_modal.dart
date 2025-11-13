import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../utils/number_utils.dart';

class SurAchatsModal extends StatefulWidget {
  const SurAchatsModal({super.key});

  @override
  State<SurAchatsModal> createState() => _SurAchatsModalState();
}

class _SurAchatsModalState extends State<SurAchatsModal> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _numRetourController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fournisseurController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();

  List<Frn> _fournisseurs = [];
  List<Achat> _achats = [];
  String? _selectedFournisseur;
  String? _selectedAchat;
  final List<Map<String, dynamic>> _lignesRetour = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeForm();
  }

  void _initializeForm() {
    final now = DateTime.now();
    _dateController.text = app_date.AppDateUtils.formatDate(now);
    _generateNextNumRetour();
  }

  Future<void> _generateNextNumRetour() async {
    // Générer le prochain numéro de retour sur achats
    final nextNum = 'RA${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _numRetourController.text = nextNum;
  }

  Future<void> _loadData() async {
    try {
      final fournisseurs = await _databaseService.database.getAllFournisseurs();
      setState(() {
        _fournisseurs = fournisseurs;
      });
    } catch (e) {
      // Error handled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _loadAchatsForFournisseur(String fournisseur) async {
    try {
      final achats = await (_databaseService.database.select(_databaseService.database.achats)
            ..where((a) => a.frns.equals(fournisseur))
            ..orderBy([(a) => drift.OrderingTerm.desc(a.daty)]))
          .get();
      setState(() {
        _achats = achats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des achats: $e')),
        );
      }
    }
  }

  Future<void> _chargerArticlesAchat() async {
    if (_selectedAchat == null) return;

    try {
      final detailsAchat = await (_databaseService.database.select(_databaseService.database.detachats)
            ..where((d) => d.numachats.equals(_selectedAchat!)))
          .get();

      setState(() {
        _lignesRetour.clear();
        for (var detail in detailsAchat) {
          _lignesRetour.add({
            'designation': detail.designation ?? '',
            'unite': detail.unites ?? '',
            'quantite': detail.q ?? 0.0,
            'prixUnitaire': detail.pu ?? 0.0,
            'montant': (detail.q ?? 0.0) * (detail.pu ?? 0.0),
            'depot': detail.depots ?? '',
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${detailsAchat.length} article(s) chargé(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des articles: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: Colors.grey[100],
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Retour sur Achats',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form section
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFE6E6FA),
              child: Column(
                children: [
                  Row(
                    children: [
                      // N° Retour
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('N° Retour:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _numRetourController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                fillColor: Color(0xFFF5F5F5),
                                filled: true,
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                suffixIcon: Icon(Icons.calendar_today, size: 16),
                              ),
                              style: const TextStyle(fontSize: 12),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  _dateController.text = app_date.AppDateUtils.formatDate(date);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Fournisseur
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fournisseur:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedFournisseur,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              items: _fournisseurs.map((frn) {
                                return DropdownMenuItem<String>(
                                  value: frn.rsoc,
                                  child: Text(frn.rsoc, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedFournisseur = value;
                                  _selectedAchat = null;
                                  _achats.clear();
                                });
                                if (value != null) {
                                  _loadAchatsForFournisseur(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Achat de référence
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Achat de référence:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedAchat,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              items: _achats.map((achat) {
                                return DropdownMenuItem<String>(
                                  value: achat.numachats,
                                  child: Text('${achat.numachats} - ${achat.nfact ?? ''}',
                                      style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAchat = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Motif
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Motif du retour:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _motifController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          hintText: 'Saisir le motif du retour...',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Articles section
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Text('Désignation',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child:
                                  Text('Unité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Qté Retour',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text('Prix Unitaire',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text('Montant',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child:
                                  Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: _lignesRetour.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun article à retourner.\nSélectionnez un achat pour charger les articles.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _lignesRetour.length,
                              itemBuilder: (context, index) {
                                final ligne = _lignesRetour[index];
                                return Container(
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                    border: const Border(
                                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            ligne['designation'] ?? '',
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text(
                                            ligne['unite'] ?? '',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text(
                                            NumberUtils.formatNumber(ligne['quantite'] ?? 0),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            NumberUtils.formatNumber(ligne['prixUnitaire'] ?? 0),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            NumberUtils.formatNumber(ligne['montant'] ?? 0),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _lignesRetour.removeAt(index);
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedAchat != null) {
                        _chargerArticlesAchat();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez sélectionner un achat')),
                        );
                      }
                    },
                    child: const Text('Charger Articles'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _lignesRetour.isNotEmpty
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Retour enregistré avec succès')),
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Valider Retour'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numRetourController.dispose();
    _dateController.dispose();
    _fournisseurController.dispose();
    _motifController.dispose();
    super.dispose();
  }
}
