import 'package:flutter/material.dart';

/// Widget pour la liste des ventes (sidebar gauche)
class VentesListWidget extends StatelessWidget {
  final Future<List<Map<String, dynamic>>>? ventesFuture;
  final String searchText;
  final String currentNumVente;
  final bool isVendeur;
  final ValueChanged<String> onVenteSelected;

  const VentesListWidget({
    super.key,
    required this.ventesFuture,
    required this.searchText,
    required this.currentNumVente,
    required this.isVendeur,
    required this.onVenteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ventesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune vente', style: TextStyle(fontSize: 11)));
        }

        final ventes = snapshot.data!;
        final filteredVentes = searchText.isEmpty
            ? ventes
            : ventes.where((v) => v['numventes'].toLowerCase().contains(searchText)).toList();

        return ListView.builder(
          itemCount: filteredVentes.length,
          itemBuilder: (context, index) {
            final vente = filteredVentes[index];
            final numVente = vente['numventes'];
            final isSelected = numVente == currentNumVente;
            final statut = vente['verification'] ?? 'JOURNAL';
            final isContrePassee = vente['contre'] == '1';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isSelected ? Border.all(color: Colors.blue[300]!, width: 1) : null,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(
                  'Vente N° $numVente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue[800] : Colors.black87,
                  ),
                ),
                subtitle: statut == 'BROUILLARD'
                    ? Text('En attente', style: TextStyle(fontSize: 9, color: Colors.orange))
                    : isContrePassee
                        ? Text('Contre-passée', style: TextStyle(fontSize: 9, color: Colors.red))
                        : null,
                onTap: () => onVenteSelected(numVente),
              ),
            );
          },
        );
      },
    );
  }
}
