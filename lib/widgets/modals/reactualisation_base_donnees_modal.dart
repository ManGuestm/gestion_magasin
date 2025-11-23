import 'package:flutter/material.dart';

import '../common/tab_navigation_widget.dart';

class ReactualisationBaseDonneesModal extends StatefulWidget {
  const ReactualisationBaseDonneesModal({super.key});

  @override
  State<ReactualisationBaseDonneesModal> createState() => _ReactualisationBaseDonneesModalState();
}

class _ReactualisationBaseDonneesModalState extends State<ReactualisationBaseDonneesModal>
    with TabNavigationMixin {
  bool _isProcessing = false;
  List<String> _operations = [];
  int _currentOperation = 0;

  final List<String> _allOperations = [
    'Vérification de l\'intégrité des données',
    'Mise à jour des stocks',
    'Recalcul des CMUP',
    'Mise à jour des soldes clients',
    'Mise à jour des soldes fournisseurs',
    'Mise à jour des soldes commerciaux',
    'Optimisation des index',
    'Nettoyage des données temporaires',
    'Sauvegarde de sécurité',
    'Finalisation',
  ];

  Future<void> _startReactualisation() async {
    setState(() {
      _isProcessing = true;
      _operations = [];
      _currentOperation = 0;
    });

    for (int i = 0; i < _allOperations.length; i++) {
      setState(() {
        _currentOperation = i;
        _operations.add('${DateTime.now().toString().substring(11, 19)} - ${_allOperations[i]}...');
      });

      // Simulation du traitement
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _operations[i] = '${_operations[i].split(' - ')[0]} - ${_allOperations[i]} ✓';
      });

      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() {
      _isProcessing = false;
      _operations
          .add('${DateTime.now().toString().substring(11, 19)} - Réactualisation terminée avec succès!');
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réactualisation de la base de données terminée'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Dialog(
        backgroundColor: Colors.grey[100],
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[100],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Réactualisation de la base de données',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cette opération va :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Vérifier l\'intégrité des données'),
                    const Text('• Recalculer tous les stocks et valeurs'),
                    const Text('• Mettre à jour les soldes des comptes'),
                    const Text('• Optimiser les performances'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _startReactualisation,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh),
                          label: Text(_isProcessing ? 'En cours...' : 'Démarrer la réactualisation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_isProcessing) ...[
                          const SizedBox(width: 16),
                          Text(
                            '${_currentOperation + 1}/${_allOperations.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (_isProcessing || _operations.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Journal des opérations:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _operations.length,
                            itemBuilder: (context, index) {
                              final operation = _operations[index];
                              final isCompleted = operation.contains('✓');
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  operation,
                                  style: TextStyle(
                                    color: isCompleted ? Colors.green : Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_isProcessing)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(
                              value: (_currentOperation + 1) / _allOperations.length,
                              backgroundColor: Colors.grey[600],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 64, color: Colors.teal),
                          SizedBox(height: 16),
                          Text(
                            'Réactualisation de la base de données',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Cliquez sur "Démarrer" pour lancer la réactualisation',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
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
}
