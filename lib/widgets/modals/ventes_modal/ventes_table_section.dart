
import 'package:flutter/material.dart';
import '../../../constants/app_functions.dart';
import 'ventes_controller.dart';

class VentesTableSection extends StatelessWidget {
  final VentesController controller;
  final bool tousDepots;

  const VentesTableSection({
    super.key,
    required this.controller,
    required this.tousDepots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Table header
          _buildTableHeader(),
          // Table body
          Expanded(
            child: _buildTableBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 25,
      decoration: BoxDecoration(color: Colors.orange[300]),
      child: Row(
        children: [
          Container(
            width: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey, width: 1),
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            child: const Icon(Icons.delete, size: 12),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'DESIGNATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'UNITES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'QUANTITES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'PRIX UNITAIRE (HT)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1),
                  bottom: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const Text(
                'MONTANT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (tousDepots)
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                ),
                child: const Text(
                  'DEPOTS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    if (controller.lignesVente.isEmpty) {
      return const Center(
        child: Text(
          'Aucun article ajouté',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: controller.lignesVente.length,
      itemExtent: 18,
      itemBuilder: (context, index) {
        final ligne = controller.lignesVente[index];
        return _buildTableRow(ligne, index);
      },
    );
  }

  Widget _buildTableRow(Map<String, dynamic> ligne, int index) {
    return MouseRegion(
      onEnter: (_) {
        // Gérer le survol
      },
      onExit: (_) {
        // Gérer la sortie du survol
      },
      child: GestureDetector(
        onTap: () {
          // Gérer le clic
        },
        child: Container(
          height: 18,
          decoration: BoxDecoration(
            color: controller.selectedRowIndex == index
                ? Colors.blue[200]
                : (index % 2 == 0 ? Colors.white : Colors.grey[50]),
          ),
          child: Row(
            children: [
              // Bouton supprimer
              Container(
                width: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey, width: 1),
                    bottom: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 12),
                  onPressed: () => _supprimerLigne(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              // Désignation
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.only(left: 4),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey, width: 1),
                      bottom: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: Text(
                    ligne['designation'] ?? '',
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Unités
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey, width: 1),
                      bottom: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: Text(
                    ligne['unites'] ?? '',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              // Quantités
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey, width: 1),
                      bottom: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: Text(
                    (ligne['quantite'] as double?)?.round().toString() ?? '0',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              // Prix unitaire
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey, width: 1),
                      bottom: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: Text(
                    AppFunctions.formatNumber(ligne['prixUnitaire']?.toDouble() ?? 0),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              // Montant
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      right: tousDepots
                          ? const BorderSide(color: Colors.grey, width: 1)
                          : BorderSide.none,
                      bottom: const BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: Text(
                    AppFunctions.formatNumber(ligne['montant']?.toDouble() ?? 0),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              // Dépôt (si tous dépôts)
              if (tousDepots)
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
                    ),
                    child: Text(
                      ligne['depot'] ?? '',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _supprimerLigne(int index) {
    // Implémenter la suppression de ligne
  }
}