import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import 'ajout_moyen_paiement_modal.dart';

class MoyenPaiementModal extends StatefulWidget {
  const MoyenPaiementModal({super.key});

  @override
  State<MoyenPaiementModal> createState() => _MoyenPaiementModalState();
}

class _MoyenPaiementModalState extends State<MoyenPaiementModal> {
  final DatabaseService _databaseService = DatabaseService();
  List<MpData> _moyensPaiement = [];
  MpData? _selectedMoyenPaiement;

  @override
  void initState() {
    super.initState();
    _loadMoyensPaiement();
  }

  Future<void> _loadMoyensPaiement() async {
    try {
      final moyens = await _databaseService.database.select(_databaseService.database.mp).get();
      setState(() {
        _moyensPaiement = moyens;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem(
          value: 'creer',
          child: Row(
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 8),
              Text('Créer'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'modifier',
          enabled: _selectedMoyenPaiement != null,
          child: const Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Modifier'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'supprimer',
          enabled: _selectedMoyenPaiement != null,
          child: const Row(
            children: [
              Icon(Icons.delete, size: 16),
              SizedBox(width: 8),
              Text('Supprimer'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value);
      }
    });
  }

  void _handleContextMenuAction(String action) {
    switch (action) {
      case 'creer':
        _showAjoutModal();
        break;
      case 'modifier':
        if (_selectedMoyenPaiement != null) {
          _showAjoutModal(moyenPaiement: _selectedMoyenPaiement);
        }
        break;
      case 'supprimer':
        if (_selectedMoyenPaiement != null) {
          _confirmerSuppression();
        }
        break;
    }
  }

  void _showAjoutModal({MpData? moyenPaiement}) {
    showDialog(
      context: context,
      builder: (context) => AjoutMoyenPaiementModal(
        moyenPaiement: moyenPaiement,
        onSaved: () {
          _loadMoyensPaiement();
          setState(() {
            _selectedMoyenPaiement = null;
          });
        },
      ),
    );
  }

  void _confirmerSuppression() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${_selectedMoyenPaiement!.mp}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _supprimerMoyenPaiement();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _supprimerMoyenPaiement() async {
    try {
      await (_databaseService.database.delete(_databaseService.database.mp)
            ..where((tbl) => tbl.mp.equals(_selectedMoyenPaiement!.mp)))
          .go();
      _loadMoyensPaiement();
      setState(() {
        _selectedMoyenPaiement = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moyen de paiement supprimé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Gestion des Moyens de Paiement',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: GestureDetector(
                  onSecondaryTapDown: (details) {
                    _showContextMenu(context, details.globalPosition);
                  },
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Moyen de Paiement',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Table content
                        Expanded(
                          child: ListView.builder(
                            itemCount: _moyensPaiement.length,
                            itemBuilder: (context, index) {
                              final moyen = _moyensPaiement[index];
                              final isSelected = _selectedMoyenPaiement?.mp == moyen.mp;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMoyenPaiement = isSelected ? null : moyen;
                                  });
                                },
                                onSecondaryTapDown: (details) {
                                  setState(() {
                                    _selectedMoyenPaiement = moyen;
                                  });
                                  _showContextMenu(context, details.globalPosition);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue[50] : Colors.white,
                                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(moyen.mp),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAjoutModal,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nouveau'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedMoyenPaiement != null
                          ? () => _showAjoutModal(moyenPaiement: _selectedMoyenPaiement)
                          : null,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedMoyenPaiement != null ? _confirmerSuppression : null,
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
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
}
