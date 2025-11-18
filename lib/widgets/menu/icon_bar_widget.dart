import 'package:flutter/material.dart';

import '../../constants/menu_data.dart';

class IconBarWidget extends StatelessWidget {
  final Function(String) onIconTap;

  const IconBarWidget({super.key, required this.onIconTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color.fromARGB(255, 230, 229, 229),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 4.0,
        runSpacing: 4.0,
        children:
            MenuData.iconButtons.map((iconData) => _buildIconButton(iconData.icon, iconData.label)).toList(),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () => onIconTap(label),
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
        color: Colors.white,
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
