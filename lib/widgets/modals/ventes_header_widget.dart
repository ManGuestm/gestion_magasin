import 'package:flutter/material.dart';

/// Widget pour l'en-tête de la vente
class VentesHeaderWidget extends StatelessWidget {
  final TextEditingController numVentesController;
  final TextEditingController dateController;
  final TextEditingController nFactureController;
  final TextEditingController heureController;
  final bool isExistingPurchase;

  const VentesHeaderWidget({
    super.key,
    required this.numVentesController,
    required this.dateController,
    required this.nFactureController,
    required this.heureController,
    required this.isExistingPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE6E6FA),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: numVentesController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'N° Vente',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: nFactureController,
              decoration: const InputDecoration(
                labelText: 'N° Fact/BL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: heureController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Heure',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
