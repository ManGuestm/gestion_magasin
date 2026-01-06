import 'package:flutter/material.dart';

import '../../database/database.dart';

class VerificationClientsModal extends StatelessWidget {
  final AppDatabase database;

  const VerificationClientsModal({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Vérification Clients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Contenu de vérification clients à implémenter'),
          ],
        ),
      ),
    );
  }
}
