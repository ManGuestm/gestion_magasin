import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../../database/database_service.dart';

class AjoutMoyenPaiementModal extends StatefulWidget {
  final MpData? moyenPaiement;
  final VoidCallback onSaved;

  const AjoutMoyenPaiementModal({
    super.key,
    this.moyenPaiement,
    required this.onSaved,
  });

  @override
  State<AjoutMoyenPaiementModal> createState() => _AjoutMoyenPaiementModalState();
}

class _AjoutMoyenPaiementModalState extends State<AjoutMoyenPaiementModal> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _mpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.moyenPaiement != null) {
      _mpController.text = widget.moyenPaiement!.mp;
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.moyenPaiement == null) {
        // Création
        await _databaseService.database.into(_databaseService.database.mp).insert(
              MpCompanion.insert(
                mp: _mpController.text.trim(),
              ),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Moyen de paiement créé avec succès')),
          );
        }
      } else {
        // Modification
        await (_databaseService.database.update(_databaseService.database.mp)
              ..where((tbl) => tbl.mp.equals(widget.moyenPaiement!.mp)))
            .write(MpCompanion(
          mp: drift.Value(_mpController.text.trim()),
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Moyen de paiement modifié avec succès')),
          );
        }
      }

      widget.onSaved();
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
  Widget build(BuildContext context) {
    final isModification = widget.moyenPaiement != null;

    return PopScope(
      canPop: false,
      child: Dialog(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    Icon(
                      isModification ? Icons.edit : Icons.add,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isModification ? 'Modifier Moyen de Paiement' : 'Nouveau Moyen de Paiement',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Moyen de Paiement *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _mpController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Ex: Espèces, Chèque, Virement...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '* Champs obligatoires',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _sauvegarder,
                      child: Text(isModification ? 'Modifier' : 'Créer'),
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

  @override
  void dispose() {
    _mpController.dispose();
    super.dispose();
  }
}
