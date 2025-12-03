import 'package:flutter/material.dart';

import 'ventes_controller.dart';

class VentesSidebar extends StatelessWidget {
  final VentesController controller;
  final bool isVendeur;
  final bool tousDepots;

  const VentesSidebar({
    super.key,
    required this.controller,
    required this.isVendeur,
    required this.tousDepots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey, width: 1)),
        color: Colors.white,
      ),
      child: isVendeur ? _buildVendeurView() : _buildAdminView(),
    );
  }

  Widget _buildVendeurView() {
    return Column(
      children: [
        // Search field
        Container(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: controller.searchVentesController,
            decoration: const InputDecoration(
              hintText: 'Rechercher vente...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              prefixIcon: Icon(Icons.search, size: 16),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // Header
        Container(
          height: 35,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Mes Ventes en attente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Sales list
        Expanded(
          child: _buildVentesListByStatus('BROUILLARD'),
        ),
      ],
    );
  }

  Widget _buildAdminView() {
    return Column(
      children: [
        // Search field
        Container(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: controller.searchVentesController,
            decoration: const InputDecoration(
              hintText: 'Rechercher vente...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              prefixIcon: Icon(Icons.search, size: 16),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // Three columns layout
        Expanded(
          child: Column(
            children: [
              // Brouillard column
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 35,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1),
                          right: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pending, size: 12, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'Brouillard',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey, width: 1),
                          ),
                        ),
                        child: _buildVentesListByStatus('BROUILLARD'),
                      ),
                    ),
                  ],
                ),
              ),
              // Journal column
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 35,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1),
                          right: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Journal (Ctrl+J)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey, width: 1),
                          ),
                        ),
                        child: _buildVentesListByStatus('JOURNAL'),
                      ),
                    ),
                  ],
                ),
              ),
              // Contre-passé column
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 35,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel, size: 12, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Contre-passé (Ctrl+Shift+X)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildVentesListByStatus('CONTRE_PASSE'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVentesListByStatus(String statut) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.ventesFuture,
      builder: (context, snapshot) {
        // Implémenter la liste des ventes
        return const Center(
          child: Text('Liste des ventes'),
        );
      },
    );
  }
}
