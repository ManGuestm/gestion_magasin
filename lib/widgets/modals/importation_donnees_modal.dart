import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';
import '../../services/audit_service.dart';
import '../common/base_modal.dart';

class ImportationDonneesModal extends StatefulWidget {
  final String type;

  const ImportationDonneesModal({super.key, required this.type});

  @override
  State<ImportationDonneesModal> createState() => _ImportationDonneesModalState();
}

class _ImportationDonneesModalState extends State<ImportationDonneesModal> {
  bool _isLoading = false;
  String? _selectedFile;
  bool _includeBalances = false;
  List<List<dynamic>> _previewData = [];
  String _importType = 'csv'; // 'csv' ou 'db'
  int _currentProgress = 0;
  int _totalItems = 0;
  String _progressMessage = '';

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Importation ${widget.type}',
      width: 800,
      height: MediaQuery.of(context).size.height * 0.9,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImportTypeSelection(),
            const SizedBox(height: 20),
            _buildFileSelection(),
            const SizedBox(height: 20),
            if (widget.type == 'Fournisseurs' || widget.type == 'Clients') _buildBalanceOption(),
            if (_previewData.isNotEmpty) ...[const SizedBox(height: 20), _buildPreview()],
            if (_isLoading) ...[const SizedBox(height: 20), _buildProgressIndicator()],
            const SizedBox(height: 20),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type d\'importation', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: _importType == 'csv' ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: Icon(
                        _importType == 'csv' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _importType == 'csv' ? Colors.blue : Colors.grey,
                      ),
                      title: const Text('Fichier CSV'),
                      subtitle: const Text('Importer depuis un fichier CSV'),
                      onTap: () => setState(() {
                        _importType = 'csv';
                        _selectedFile = null;
                        _previewData = [];
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: _importType == 'db' ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: Icon(
                        _importType == 'db' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _importType == 'db' ? Colors.blue : Colors.grey,
                      ),
                      title: const Text('Base de données'),
                      subtitle: const Text('Importer depuis un fichier .db'),
                      onTap: () => setState(() {
                        _importType = 'db';
                        _selectedFile = null;
                        _previewData = [];
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionner le fichier ${_importType.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _selectedFile ?? 'Aucun fichier sélectionné',
                      style: TextStyle(color: _selectedFile != null ? Colors.black : Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _selectFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Parcourir'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_getFormatDescription(), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceOption() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CheckboxListTile(
          title: Text('Inclure les soldes ${widget.type.toLowerCase()}'),
          subtitle: Text('Cochez cette option pour importer les soldes dus aux ${widget.type.toLowerCase()}'),
          value: _includeBalances,
          onChanged: (value) => setState(() => _includeBalances = value ?? false),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SizedBox(
      height: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aperçu des données (${_previewData.length - 1} lignes)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: _previewData.isNotEmpty
                          ? _previewData[0]
                                .map<DataColumn>((header) => DataColumn(label: Text(header.toString())))
                                .toList()
                          : [],
                      rows: _previewData
                          .skip(1)
                          .take(10)
                          .map<DataRow>(
                            (row) => DataRow(
                              cells: row.map<DataCell>((cell) => DataCell(Text(cell.toString()))).toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Importation en cours...', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _totalItems > 0 ? _currentProgress / _totalItems : null),
            const SizedBox(height: 8),
            Text(
              _totalItems > 0 ? '$_currentProgress / $_totalItems éléments importés' : _progressMessage,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _selectedFile != null && !_isLoading ? _importData : null,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Importer'),
        ),
      ],
    );
  }

  String _getFormatDescription() {
    switch (widget.type) {
      case 'Articles':
        return _importType == 'csv'
            ? 'Format: Code, Désignation, Prix Achat, Prix Vente, Unité, Stock Initial'
            : 'Table: articles';
      case 'Fournisseurs':
        return _importType == 'csv'
            ? 'Format: Code, Nom, Adresse, Téléphone, Email${_includeBalances ? ', Solde' : ''}'
            : 'Table: frns';
      case 'Clients':
        return _importType == 'csv'
            ? 'Format: Code, Nom, Adresse, Téléphone, Email${_includeBalances ? ', Solde' : ''}'
            : 'Table: clt';
      case 'Moyens de paiement':
        return _importType == 'csv'
            ? 'Format: Code, Libellé, Type (Espèces/Chèque/Virement/Carte)'
            : 'Table: mp';
      default:
        return _importType == 'csv' ? 'Fichier CSV avec en-têtes' : 'Base de données SQLite';
    }
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _importType == 'csv' ? ['csv'] : ['db', 'sqlite', 'sqlite3'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single.path;
        });
        if (_importType == 'csv') {
          await _loadPreview();
        } else {
          await _loadDbPreview();
        }
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du fichier: $e');
    }
  }

  Future<void> _loadPreview() async {
    if (_selectedFile == null) return;

    try {
      final file = File(_selectedFile!);
      final contents = await file.readAsString(encoding: utf8);
      final csvData = const CsvToListConverter().convert(contents);

      setState(() {
        _previewData = csvData;
      });
    } catch (e) {
      _showError('Erreur lors de la lecture du fichier: $e');
    }
  }

  Future<void> _loadDbPreview() async {
    if (_selectedFile == null) return;

    try {
      final externalDb = DatabaseService.fromPath(_selectedFile!);
      final tableName = _getTableName();

      final result = await externalDb.database.customSelect('SELECT * FROM $tableName LIMIT 10').get();

      if (result.isNotEmpty) {
        final headers = result.first.data.keys.toList();
        final rows = result.map((row) => row.data.values.toList()).toList();

        setState(() {
          _previewData = [headers, ...rows];
        });
      }

      await externalDb.close();
    } catch (e) {
      _showError('Erreur lors de la lecture de la base: $e');
    }
  }

  String _getTableName() {
    switch (widget.type) {
      case 'Articles':
        return 'articles';
      case 'Fournisseurs':
        return 'frns';
      case 'Clients':
        return 'clt';
      case 'Moyens de paiement':
        return 'mp';
      default:
        return 'articles';
    }
  }

  Future<void> _importData() async {
    if (_selectedFile == null || _previewData.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentProgress = 0;
      _totalItems = _importType == 'csv' ? _previewData.length - 1 : 0;
      _progressMessage = 'Préparation de l\'importation...';
    });

    try {
      final db = DatabaseService().database;
      int imported = 0;

      if (_importType == 'csv') {
        // Skip header row for CSV
        for (int i = 1; i < _previewData.length; i++) {
          final row = _previewData[i];
          await _importRow(db, row);
          imported++;

          setState(() {
            _currentProgress = imported;
            _progressMessage = 'Importation de ${widget.type.toLowerCase()}...';
          });

          // Petite pause pour permettre à l'UI de se mettre à jour
          if (imported % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }
      } else {
        // Import from external database
        imported = await _importFromDatabase();
      }

      await AuditService().log(
        userId: 'current_user',
        userName: 'Current User',
        action: AuditAction.create,
        module: 'IMPORT',
        details: 'Importation de $imported ${widget.type.toLowerCase()}',
      );

      _showSuccess('$imported ${widget.type.toLowerCase()} importé(s) avec succès');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('Erreur lors de l\'importation: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _currentProgress = 0;
        _totalItems = 0;
        _progressMessage = '';
      });
    }
  }

  Future<void> _importArticle(AppDatabase db, List<dynamic> row) async {
    if (row.length < 6) return;

    await db.insertArticle(
      ArticlesCompanion(
        designation: Value(row[1].toString()),
        u1: Value(row[4].toString()),
        pvu1: Value(double.tryParse(row[3].toString()) ?? 0),
        stocksu1: Value(double.tryParse(row[5].toString()) ?? 0),
        cmup: Value(double.tryParse(row[2].toString()) ?? 0),
        action: const Value('A'),
      ),
    );
  }

  Future<void> _importFournisseur(AppDatabase db, List<dynamic> row) async {
    if (row.length < 5) return;

    await db.insertFournisseur(
      FrnsCompanion(
        rsoc: Value(row[1].toString()),
        adr: Value(row[2].toString()),
        tel: Value(row[3].toString()),
        email: Value(row[4].toString()),
        action: const Value('A'),
        soldes: _includeBalances && row.length > 5
            ? Value(double.tryParse(row[5].toString()) ?? 0)
            : const Value(0),
      ),
    );

    if (_includeBalances && row.length > 5) {
      final solde = double.tryParse(row[5].toString()) ?? 0;
      if (solde != 0) {
        final ref = 'FRN${DateTime.now().millisecondsSinceEpoch}';
        await db.insertComptefrns(
          ComptefrnsCompanion(
            ref: Value(ref),
            daty: Value(DateTime.now()),
            lib: Value('Solde initial import'),
            frns: Value(row[1].toString()),
            solde: Value(solde),
            entres: Value(solde),
            sortie: const Value(0),
          ),
        );
      }
    }
  }

  Future<void> _importClient(AppDatabase db, List<dynamic> row) async {
    if (row.length < 5) return;

    await db.insertClient(
      CltCompanion(
        rsoc: Value(row[1].toString()),
        adr: Value(row[2].toString()),
        tel: Value(row[3].toString()),
        email: Value(row[4].toString()),
        action: const Value('A'),
        soldes: _includeBalances && row.length > 5
            ? Value(double.tryParse(row[5].toString()) ?? 0)
            : const Value(0),
      ),
    );

    if (_includeBalances && row.length > 5) {
      final solde = double.tryParse(row[5].toString()) ?? 0;
      if (solde != 0) {
        final ref = 'CLT${DateTime.now().millisecondsSinceEpoch}';
        await db.insertCompteclt(
          ComptecltCompanion(
            ref: Value(ref),
            daty: Value(DateTime.now()),
            lib: Value('Solde initial import'),
            clt: Value(row[1].toString()),
            solde: Value(solde),
            entres: Value(solde),
            sorties: const Value(0),
          ),
        );
      }
    }
  }

  Future<void> _importRow(AppDatabase db, List<dynamic> row) async {
    switch (widget.type) {
      case 'Articles':
        await _importArticle(db, row);
        break;
      case 'Fournisseurs':
        await _importFournisseur(db, row);
        break;
      case 'Clients':
        await _importClient(db, row);
        break;
      case 'Moyens de paiement':
        await _importMoyenPaiement(db, row);
        break;
    }
  }

  Future<int> _importFromDatabase() async {
    if (_selectedFile == null) return 0;

    try {
      final externalDb = DatabaseService.fromPath(_selectedFile!);
      final db = DatabaseService().database;
      int totalImported = 0;

      if (widget.type == 'Articles') {
        // Importer articles, depart et depots
        final tables = ['articles', 'depart', 'depots'];
        int totalRows = 0;

        // Calculer le total de lignes
        for (final table in tables) {
          try {
            final count = await externalDb.database
                .customSelect('SELECT COUNT(*) as count FROM $table')
                .getSingleOrNull();
            totalRows += count?.read<int>('count') ?? 0;
          } catch (e) {
            // Table n'existe pas, continuer
          }
        }

        setState(() {
          _totalItems = totalRows;
          _progressMessage = 'Importation articles, départs et dépôts...';
        });

        // Importer chaque table
        for (final table in tables) {
          try {
            final result = await externalDb.database.customSelect('SELECT * FROM $table').get();
            for (final row in result) {
              switch (table) {
                case 'articles':
                  await _importArticleFromDb(db, row.data);
                  break;
                case 'depart':
                  await _importDepartFromDb(db, row.data);
                  break;
                case 'depots':
                  await _importDepotFromDb(db, row.data);
                  break;
              }
              totalImported++;
              setState(() => _currentProgress = totalImported);

              if (totalImported % 10 == 0) {
                await Future.delayed(const Duration(milliseconds: 1));
              }
            }
          } catch (e) {
            // Table n'existe pas ou erreur, continuer avec la suivante
          }
        }
      } else if (widget.type == 'Fournisseurs') {
        // Importation fournisseurs avec gestion des soldes
        final tables = _includeBalances ? ['frns', 'comptefrns'] : ['frns'];
        int totalRows = 0;

        // Calculer le total de lignes
        for (final table in tables) {
          try {
            final count = await externalDb.database
                .customSelect('SELECT COUNT(*) as count FROM $table')
                .getSingleOrNull();
            totalRows += count?.read<int>('count') ?? 0;
          } catch (e) {
            // Table n'existe pas, continuer
          }
        }

        setState(() {
          _totalItems = totalRows;
          _progressMessage = 'Importation fournisseurs...';
        });

        // Importer frns
        try {
          final result = await externalDb.database.customSelect('SELECT * FROM frns').get();
          for (final row in result) {
            await _importFournisseurFromDb(db, row.data);
            totalImported++;
            setState(() => _currentProgress = totalImported);

            if (totalImported % 10 == 0) {
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }
        } catch (e) {
          // Table frns n'existe pas
        }

        // Importer comptefrns si inclure soldes
        if (_includeBalances) {
          try {
            final result = await externalDb.database.customSelect('SELECT * FROM comptefrns').get();
            for (final row in result) {
              await _importComptefrnsFromDb(db, row.data);
              totalImported++;
              setState(() => _currentProgress = totalImported);

              if (totalImported % 10 == 0) {
                await Future.delayed(const Duration(milliseconds: 1));
              }
            }
          } catch (e) {
            // Table comptefrns n'existe pas
          }
        }
      } else if (widget.type == 'Clients') {
        // Importation clients avec gestion des soldes
        final tables = _includeBalances ? ['clt', 'compteclt'] : ['clt'];
        int totalRows = 0;

        // Calculer le total de lignes
        for (final table in tables) {
          try {
            final count = await externalDb.database
                .customSelect('SELECT COUNT(*) as count FROM $table')
                .getSingleOrNull();
            totalRows += count?.read<int>('count') ?? 0;
          } catch (e) {
            // Table n'existe pas, continuer
          }
        }

        setState(() {
          _totalItems = totalRows;
          _progressMessage = 'Importation clients...';
        });

        // Importer clt
        try {
          final result = await externalDb.database.customSelect('SELECT * FROM clt').get();
          for (final row in result) {
            await _importClientFromDb(db, row.data);
            totalImported++;
            setState(() => _currentProgress = totalImported);

            if (totalImported % 10 == 0) {
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }
        } catch (e) {
          // Table clt n'existe pas
        }

        // Importer compteclt si inclure soldes
        if (_includeBalances) {
          try {
            final result = await externalDb.database.customSelect('SELECT * FROM compteclt').get();
            for (final row in result) {
              await _importComptecltFromDb(db, row.data);
              totalImported++;
              setState(() => _currentProgress = totalImported);

              if (totalImported % 10 == 0) {
                await Future.delayed(const Duration(milliseconds: 1));
              }
            }
          } catch (e) {
            // Table compteclt n'existe pas
          }
        }
      } else {
        // Importation normale pour les autres types
        final tableName = _getTableName();
        final result = await externalDb.database.customSelect('SELECT * FROM $tableName').get();

        setState(() {
          _totalItems = result.length;
          _progressMessage = 'Importation depuis la base de données...';
        });

        for (final row in result) {
          switch (widget.type) {
            case 'Moyens de paiement':
              await _importMoyenPaiementFromDb(db, row.data);
              break;
          }
          totalImported++;
          setState(() => _currentProgress = totalImported);

          if (totalImported % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }
      }

      await externalDb.close();
      return totalImported;
    } catch (e) {
      throw Exception('Erreur importation base: $e');
    }
  }

  Future<void> _importArticleFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db.insertArticle(
      ArticlesCompanion(
        designation: Value(data['designation']?.toString() ?? ''),
        u1: Value(data['u1']?.toString() ?? ''),
        pvu1: Value(data['pvu1']?.toDouble() ?? 0),
        stocksu1: Value(data['stocksu1']?.toDouble() ?? 0),
        cmup: Value(data['cmup']?.toDouble() ?? 0),
        action: const Value('A'),
      ),
    );
  }

  Future<void> _importFournisseurFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db.insertFournisseur(
      FrnsCompanion(
        rsoc: Value(data['rsoc']?.toString() ?? ''),
        adr: Value(data['adr']?.toString() ?? ''),
        tel: Value(data['tel']?.toString() ?? ''),
        email: Value(data['email']?.toString() ?? ''),
        action: const Value('A'),
        soldes: _includeBalances ? Value(data['soldes']?.toDouble() ?? 0) : const Value(0),
      ),
    );
  }

  Future<void> _importComptefrnsFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db.insertComptefrns(
      ComptefrnsCompanion(
        ref: Value(data['ref']?.toString() ?? ''),
        daty: Value(DateTime.tryParse(data['daty']?.toString() ?? '') ?? DateTime.now()),
        lib: Value(data['lib']?.toString() ?? ''),
        frns: Value(data['frns']?.toString() ?? ''),
        solde: Value(data['solde']?.toDouble() ?? 0),
        entres: Value(data['entres']?.toDouble() ?? 0),
        sortie: Value(data['sortie']?.toDouble() ?? 0),
      ),
    );
  }

  Future<void> _importClientFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db.insertClient(
      CltCompanion(
        rsoc: Value(data['rsoc']?.toString() ?? ''),
        adr: Value(data['adr']?.toString() ?? ''),
        tel: Value(data['tel']?.toString() ?? ''),
        email: Value(data['email']?.toString() ?? ''),
        action: const Value('A'),
        soldes: _includeBalances ? Value(data['soldes']?.toDouble() ?? 0) : const Value(0),
        datedernop: _includeBalances
            ? Value(DateTime.tryParse(data['datedernop']?.toString() ?? ''))
            : const Value(null),
      ),
    );
  }

  Future<void> _importComptecltFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db.insertCompteclt(
      ComptecltCompanion(
        ref: Value(data['ref']?.toString() ?? ''),
        daty: Value(DateTime.tryParse(data['daty']?.toString() ?? '') ?? DateTime.now()),
        lib: Value(data['lib']?.toString() ?? ''),
        clt: Value(data['clt']?.toString() ?? ''),
        solde: Value(data['solde']?.toDouble() ?? 0),
        entres: Value(data['entres']?.toDouble() ?? 0),
        sorties: Value(data['sorties']?.toDouble() ?? 0),
      ),
    );
  }

  Future<void> _importMoyenPaiementFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db.into(db.mp).insert(MpCompanion(mp: Value(data['mp']?.toString() ?? '')));
  }

  Future<void> _importMoyenPaiement(AppDatabase db, List<dynamic> row) async {
    if (row.length < 2) return;
    await db.into(db.mp).insert(MpCompanion(mp: Value(row[1].toString())));
  }

  Future<void> _importDepartFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db
        .into(db.depart)
        .insert(
          DepartCompanion(
            designation: Value(data['designation']?.toString() ?? ''),
            depots: Value(data['depots']?.toString() ?? ''),
            stocksu1: Value(data['stocksu1']?.toDouble() ?? 0),
            stocksu2: Value(data['stocksu2']?.toDouble() ?? 0),
            stocksu3: Value(data['stocksu3']?.toDouble() ?? 0),
          ),
        );
  }

  Future<void> _importDepotFromDb(AppDatabase db, Map<String, dynamic> data) async {
    await db.into(db.depots).insert(DepotsCompanion(depots: Value(data['depots']?.toString() ?? '')));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }
}
