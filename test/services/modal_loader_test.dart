import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_magasin/services/modal_loader.dart';

void main() {
  group('ModalLoader Tests', () {
    setUp(() {
      ModalLoader.clearCache();
    });

    test('should load modal successfully', () async {
      final modal = await ModalLoader.loadModal('Articles');
      expect(modal, isNotNull);
    });

    test('should return null for unknown modal', () async {
      final modal = await ModalLoader.loadModal('UnknownModal');
      expect(modal, isNull);
    });

    test('should cache frequent modals', () async {
      await ModalLoader.loadModal('Articles');
      expect(ModalLoader.getCacheSize(), equals(1));
      expect(ModalLoader.getCachedModals(), contains('Articles'));
    });

    test('should not cache non-frequent modals', () async {
      await ModalLoader.loadModal('À propos');
      expect(ModalLoader.getCacheSize(), equals(0));
    });

    test('should clear cache', () async {
      await ModalLoader.loadModal('Articles');
      ModalLoader.clearCache();
      expect(ModalLoader.getCacheSize(), equals(0));
    });
  });
}