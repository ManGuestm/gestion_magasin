import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_magasin/widgets/common/tab_navigation_widget.dart';

void main() {
  group('TabNavigationMixin Tests', () {
    testWidgets('Tab navigation should move to next field', (WidgetTester tester) async {
      final testWidget = TestTabNavigationWidget();

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // Focus on first field
      await tester.tap(find.byKey(const Key('field1')));
      await tester.pump();

      // Press Tab
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify second field is focused
      expect(testWidget.getCurrentFocusIndex(), equals(1));
    });

    testWidgets('Shift+Tab navigation should move to previous field', (WidgetTester tester) async {
      final testWidget = TestTabNavigationWidget();

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // Focus on second field
      await tester.tap(find.byKey(const Key('field2')));
      await tester.pump();

      // Press Shift+Tab
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();

      // Verify first field is focused
      expect(testWidget.getCurrentFocusIndex(), equals(0));
    });

    testWidgets('Tab navigation should wrap around at boundaries', (WidgetTester tester) async {
      final testWidget = TestTabNavigationWidget();

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // Focus on last field
      await tester.tap(find.byKey(const Key('field3')));
      await tester.pump();

      // Press Tab (should not move beyond last field)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify still on last field
      expect(testWidget.getCurrentFocusIndex(), equals(2));
    });

    testWidgets('Shift+Tab navigation should not move before first field', (WidgetTester tester) async {
      final testWidget = TestTabNavigationWidget();

      await tester.pumpWidget(MaterialApp(home: testWidget));

      // Focus on first field
      await tester.tap(find.byKey(const Key('field1')));
      await tester.pump();

      // Press Shift+Tab (should not move before first field)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();

      // Verify still on first field
      expect(testWidget.getCurrentFocusIndex(), equals(0));
    });
  });
}

class TestTabNavigationWidget extends StatefulWidget {
  late final GlobalKey<_TestTabNavigationWidgetState> _key;

  TestTabNavigationWidget({super.key}) {
    _key = GlobalKey<_TestTabNavigationWidgetState>();
  }

  int getCurrentFocusIndex() => _key.currentState?._currentFocusIndex ?? 0;

  @override
  State<TestTabNavigationWidget> createState() => _TestTabNavigationWidgetState();
}

class _TestTabNavigationWidgetState extends State<TestTabNavigationWidget> with TabNavigationMixin {
  late final FocusNode _field1FocusNode;
  late final FocusNode _field2FocusNode;
  late final FocusNode _field3FocusNode;

  final _field1Controller = TextEditingController();
  final _field2Controller = TextEditingController();
  final _field3Controller = TextEditingController();

  int get _currentFocusIndex {
    final nodes = [_field1FocusNode, _field2FocusNode, _field3FocusNode];
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].hasFocus) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();

    _field1FocusNode = createFocusNode();
    _field2FocusNode = createFocusNode();
    _field3FocusNode = createFocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => handleTabNavigation(event),
      child: Scaffold(
        body: Column(
          children: [
            TextFormField(
              key: const Key('field1'),
              controller: _field1Controller,
              focusNode: _field1FocusNode,
              decoration: const InputDecoration(labelText: 'Field 1'),
              onTap: () => updateFocusIndex(_field1FocusNode),
            ),
            TextFormField(
              key: const Key('field2'),
              controller: _field2Controller,
              focusNode: _field2FocusNode,
              decoration: const InputDecoration(labelText: 'Field 2'),
              onTap: () => updateFocusIndex(_field2FocusNode),
            ),
            TextFormField(
              key: const Key('field3'),
              controller: _field3Controller,
              focusNode: _field3FocusNode,
              decoration: const InputDecoration(labelText: 'Field 3'),
              onTap: () => updateFocusIndex(_field3FocusNode),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    _field3Controller.dispose();
    super.dispose();
  }
}
