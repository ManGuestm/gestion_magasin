import 'package:flutter/material.dart';

class MenuBarWidget extends StatelessWidget {
  final Function(String) onMenuTap;

  const MenuBarWidget({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      color: Colors.grey[200],
      child: Row(
        children: ['Fichier', 'Paramètres', 'Commerces', 'Gestions', 'Trésoreries', 'États', '?']
            .map((title) => _buildMenuItem(title))
            .toList(),
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return GestureDetector(
      onTap: () => onMenuTap(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
