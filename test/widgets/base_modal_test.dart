import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_magasin/widgets/common/base_modal.dart';

void main() {
  group('BaseModal Tests', () {
    testWidgets('should display title and content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BaseModal(
              title: 'Test Modal',
              content: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Modal'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should call onClose when close button pressed', (WidgetTester tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BaseModal(
              title: 'Test Modal',
              content: const Text('Test Content'),
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(closeCalled, isTrue);
    });
  });
}
