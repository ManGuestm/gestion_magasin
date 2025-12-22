import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class MenuBarWidget extends StatelessWidget {
  final Function(String) onMenuTap;

  const MenuBarWidget({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final menus = _filterMenusByRole([
      'Fichier',
      'Paramètres',
      'Commerces',
      'Gestions',
      'Trésoreries',
      'États',
      '?',
    ]);
    return Container(
      height: 35,
      color: Colors.grey[200],
      child: Row(children: menus.map((title) => _buildMenuItem(title)).toList()),
    );
  }

  List<String> _filterMenusByRole(List<String> menus) {
    final authService = AuthService();
    final userRole = authService.currentUserRole;

    if (userRole == 'Vendeur') {
      return menus
          .where(
            (menu) =>
                menu != 'Paramètres' &&
                menu != 'Commerces' &&
                menu != 'Gestions' &&
                menu != 'Trésoreries' &&
                menu != 'États',
          )
          .toList();
    }

    return menus;
  }

  Widget _buildMenuItem(String title) {
    return GestureDetector(
      onTap: () => onMenuTap(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(title, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
