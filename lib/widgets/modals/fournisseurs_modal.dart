import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;

import '../../database/database.dart';
import '../../database/database_service.dart';

class FournisseursModal extends StatefulWidget {
  const FournisseursModal({super.key});

  @override
  State<FournisseursModal> createState() => _FournisseursModalState();
}

class _FournisseursModalState extends State<FournisseursModal> {
  final DatabaseService _databaseService = DatabaseService();
  
  // Controllers
  final TextEditingController _rsocController = TextEditingController();
  final TextEditingController _adrController = TextEditingController();
  final TextEditingController _capitalController = TextEditingController();
  final TextEditingController _rcsController = TextEditingController();
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _statController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _faxController = TextEditingController();
  final TextEditingController _telexController = TextEditingController();
  final TextEditingController _soldesController = TextEditingController();
  final TextEditingController _delaiController = TextEditingController();
  final TextEditingController _soldesaController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Frn> _fournisseurs = [];
  List<Frn> _filteredFournisseurs = [];
  Frn? _selectedFournisseur;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadFournisseurs();
  }

  Future<void> _loadFournisseurs() async {
    try {
      final fournisseurs = await _databaseService.database.getAllFournisseurs();
      setState(() {
        _fournisseurs = fournisseurs;
        _filteredFournisseurs = fournisseurs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _filterFournisseurs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFournisseurs = _fournisseurs;
      } else {
        _filteredFournisseurs = _fournisseurs.where((frn) =>
          frn.rsoc.toLowerCase().contains(query.toLowerCase()) ||
          (frn.tel?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (frn.email?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
      }
    });
  }

  void _selectFournisseur(Frn fournisseur) {
    setState(() {
      _selectedFournisseur = fournisseur;
      _isEditing = true;
      
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
      _soldesController.text = fournisseur.soldes?.toString() ?? '0';
      _delaiController.text = fournisseur.delai?.toString() ?? '';
      _soldesaController.text = fournisseur.soldesa?.toString() ?? '0';
      _actionController.text = fournisseur.action ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _selectedFournisseur = null;
      _isEditing = false;
    });
    
    _rsocController.clear();
    _adrController.clear();
    _capitalController.clear();
    _rcsController.clear();
    _nifController.clear();
    _statController.clear();
    _telController.clear();
    _portController.clear();
    _emailController.clear();
    _siteController.clear();
    _faxController.clear();
    _telexController.clear();
    _soldesController.text = '0';
    _delaiController.clear();
    _soldesaController.text = '0';
    _actionController.clear();
  }

  Future<void> _saveFournisseur() async {
    if (_rsocController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La raison sociale est obligatoire')),
      );
      return;
    }

    try {
      final companion = FrnsCompanion(
        rsoc: Value(_rsocController.text.trim()),
        adr: Value(_adrController.text.trim().isEmpty ? null : _adrController.text.trim()),
        capital: Value(double.tryParse(_capitalController.text)),
        rcs: Value(_rcsController.text.trim().isEmpty ? null : _rcsController.text.trim()),
        nif: Value(_nifController.text.trim().isEmpty ? null : _nifController.text.trim()),
        stat: Value(_statController.text.trim().isEmpty ? null : _statController.text.trim()),
        tel: Value(_telController.text.trim().isEmpty ? null : _telController.text.trim()),
        port: Value(_portController.text.trim().isEmpty ? null : _portController.text.trim()),
        email: Value(_emailController.text.trim().isEmpty ? null : _emailController.text.trim()),
        site: Value(_siteController.text.trim().isEmpty ? null : _siteController.text.trim()),
        fax: Value(_faxController.text.trim().isEmpty ? null : _faxController.text.trim()),
        telex: Value(_telexController.text.trim().isEmpty ? null : _telexController.text.trim()),
        soldes: Value(double.tryParse(_soldesController.text) ?? 0),
        datedernop: Value(DateTime.now()),
        delai: Value(int.tryParse(_delaiController.text)),
        soldesa: Value(double.tryParse(_soldesaController.text) ?? 0),
        action: Value(_actionController.text.trim().isEmpty ? null : _actionController.text.trim()),
      );

      if (_isEditing && _selectedFournisseur != null) {
        await _databaseService.database.updateFournisseur(_selectedFournisseur!.rsoc, companion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fournisseur modifié avec succès')),
          );
        }
      } else {
        await _databaseService.database.insertFournisseur(companion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fournisseur ajouté avec succès')),
          );
        }
      }

      _clearForm();
      await _loadFournisseurs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }

  Future<void> _deleteFournisseur() async {
    if (_selectedFournisseur == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer le fournisseur "${_selectedFournisseur!.rsoc}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.database.deleteFournisseur(_selectedFournisseur!.rsoc);
        _clearForm();
        await _loadFournisseurs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fournisseur supprimé avec succès')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[100],
      child: Container(
        width: 1000,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Gestion des Fournisseurs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                children: [
                  // Liste des fournisseurs
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          // Barre de recherche
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Rechercher un fournisseur',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _filterFournisseurs,
                            ),
                          ),
                          
                          // Liste
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredFournisseurs.length,
                              itemBuilder: (context, index) {
                                final fournisseur = _filteredFournisseurs[index];
                                final isSelected = _selectedFournisseur?.rsoc == fournisseur.rsoc;
                                
                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: Colors.blue.shade100,
                                  title: Text(
                                    fournisseur.rsoc,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (fournisseur.tel != null)
                                        Text('Tél: ${fournisseur.tel}'),
                                      if (fournisseur.email != null)
                                        Text('Email: ${fournisseur.email}'),
                                      Text('Solde: ${fournisseur.soldes ?? 0}'),
                                    ],
                                  ),
                                  onTap: () => _selectFournisseur(fournisseur),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Formulaire de saisie
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Modifier le fournisseur' : 'Nouveau fournisseur',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Informations générales
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _rsocController,
                                            decoration: const InputDecoration(
                                              labelText: 'Raison sociale *',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _capitalController,
                                            decoration: const InputDecoration(
                                              labelText: 'Capital',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    TextField(
                                      controller: _adrController,
                                      decoration: const InputDecoration(
                                        labelText: 'Adresse',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Informations légales
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _rcsController,
                                            decoration: const InputDecoration(
                                              labelText: 'RCS',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _nifController,
                                            decoration: const InputDecoration(
                                              labelText: 'NIF',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _statController,
                                            decoration: const InputDecoration(
                                              labelText: 'STAT',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Contact
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _telController,
                                            decoration: const InputDecoration(
                                              labelText: 'Téléphone',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _portController,
                                            decoration: const InputDecoration(
                                              labelText: 'Portable',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _faxController,
                                            decoration: const InputDecoration(
                                              labelText: 'Fax',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _emailController,
                                            decoration: const InputDecoration(
                                              labelText: 'Email',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _siteController,
                                            decoration: const InputDecoration(
                                              labelText: 'Site web',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Informations financières
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _soldesController,
                                            decoration: const InputDecoration(
                                              labelText: 'Solde',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _soldesaController,
                                            decoration: const InputDecoration(
                                              labelText: 'Solde antérieur',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _delaiController,
                                            decoration: const InputDecoration(
                                              labelText: 'Délai (jours)',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    TextField(
                                      controller: _actionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Action/Notes',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Boutons d'action
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _saveFournisseur,
                                  icon: Icon(_isEditing ? Icons.edit : Icons.add),
                                  label: Text(_isEditing ? 'Modifier' : 'Ajouter'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                ElevatedButton.icon(
                                  onPressed: _clearForm,
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Nouveau'),
                                ),
                                const SizedBox(width: 8),
                                
                                if (_isEditing)
                                  ElevatedButton.icon(
                                    onPressed: _deleteFournisseur,
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Supprimer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
    _soldesController.dispose();
    _delaiController.dispose();
    _soldesaController.dispose();
    _actionController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}