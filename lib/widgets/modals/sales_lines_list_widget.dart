import 'package:flutter/material.dart';

import '../../constants/app_functions.dart';

/// Widget pour afficher la liste des lignes de vente
class SalesLinesListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> lignesVente;
  final VoidCallback Function(int) onEditLine;
  final VoidCallback Function(int) onDeleteLine;
  final bool isVendeur;

  const SalesLinesListWidget({
    super.key,
    required this.lignesVente,
    required this.onEditLine,
    required this.onDeleteLine,
    required this.isVendeur,
  });

  @override
  Widget build(BuildContext context) {
    if (lignesVente.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Aucune ligne ajoutée', style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Désignation')),
          DataColumn(label: Text('Unité')),
          DataColumn(label: Text('Quantité')),
          DataColumn(label: Text('P.U.')),
          DataColumn(label: Text('Montant')),
          DataColumn(label: Text('Dépôt')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(lignesVente.length, (index) => _buildDataRow(context, index)),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, int index) {
    final ligne = lignesVente[index];

    return DataRow(
      cells: [
        DataCell(Text(ligne['designation'] ?? '')),
        DataCell(Text(ligne['unites'] ?? '')),
        DataCell(Text(ligne['quantite']?.toString() ?? '')),
        DataCell(Text(AppFunctions.formatNumber(ligne['prixUnitaire'] ?? 0.0))),
        DataCell(Text(AppFunctions.formatNumber(ligne['quantite'] * ligne['prixUnitaire'] ?? 0.0))),
        DataCell(Text(ligne['depot'] ?? '')),
        DataCell(
          Row(
            children: [
              IconButton(icon: Icon(Icons.edit), onPressed: () => onEditLine(index)(), tooltip: 'Modifier'),
              if (!isVendeur)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirm(context, index),
                  tooltip: 'Supprimer',
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirm(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette ligne ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              onDeleteLine(index)();
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
