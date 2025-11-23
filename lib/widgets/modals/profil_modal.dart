import 'package:flutter/material.dart';

import '../../screens/profil_screen.dart';

class ProfilModal extends StatelessWidget {
  const ProfilModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: const ProfilScreen(),
      ),
    );
  }
}
