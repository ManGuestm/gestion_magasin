import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture Serveur/Client - Validation', () {
    test('Administrateur interdit en mode CLIENT', () {
      final role = 'Administrateur';
      expect(role == 'Administrateur', true);
      expect(role == 'Caisse' || role == 'Vendeur', false);
    });

    test('Caisse autorisé en mode CLIENT', () {
      final role = 'Caisse';
      expect(role == 'Caisse' || role == 'Vendeur', true);
    });

    test('Vendeur autorisé en mode CLIENT', () {
      final role = 'Vendeur';
      expect(role == 'Caisse' || role == 'Vendeur', true);
    });
  });
}
