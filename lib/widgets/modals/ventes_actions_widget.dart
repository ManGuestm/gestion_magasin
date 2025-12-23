import 'package:flutter/material.dart';

/// Widget pour les boutons d'action de la vente
class VentesActionsWidget extends StatelessWidget {
  final bool isExistingPurchase;
  final bool peutValiderBrouillard;
  final bool isVendeur;
  final VoidCallback onNouvelle;
  final VoidCallback onValider;
  final VoidCallback onValiderBrouillard;
  final VoidCallback onContrePasser;
  final VoidCallback onImprimerFacture;
  final VoidCallback onImprimerBL;
  final VoidCallback onApercuFacture;
  final VoidCallback onApercuBL;

  const VentesActionsWidget({
    super.key,
    required this.isExistingPurchase,
    required this.peutValiderBrouillard,
    required this.isVendeur,
    required this.onNouvelle,
    required this.onValider,
    required this.onValiderBrouillard,
    required this.onContrePasser,
    required this.onImprimerFacture,
    required this.onImprimerBL,
    required this.onApercuFacture,
    required this.onApercuBL,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: onNouvelle,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nouvelle (Ctrl+N)'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          if (!isExistingPurchase)
            ElevatedButton.icon(
              onPressed: onValider,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Enregistrer (Ctrl+S)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          if (peutValiderBrouillard && !isVendeur)
            ElevatedButton.icon(
              onPressed: onValiderBrouillard,
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Valider → Journal (F3)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          if (isExistingPurchase)
            ElevatedButton.icon(
              onPressed: onContrePasser,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Contre-passer (Ctrl+D)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ElevatedButton.icon(
            onPressed: onImprimerFacture,
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Imprimer Facture (Ctrl+P)'),
          ),
          ElevatedButton.icon(
            onPressed: onImprimerBL,
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Imprimer BL (Ctrl+Shift+P)'),
          ),
          ElevatedButton.icon(
            onPressed: onApercuFacture,
            icon: const Icon(Icons.preview, size: 16),
            label: const Text('Aperçu Facture'),
          ),
          ElevatedButton.icon(
            onPressed: onApercuBL,
            icon: const Icon(Icons.preview, size: 16),
            label: const Text('Aperçu BL'),
          ),
        ],
      ),
    );
  }
}
