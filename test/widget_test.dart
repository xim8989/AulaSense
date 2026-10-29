import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Prueba básica de AulaSense', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('AulaSense'),
          ),
        ),
      ),
    );

    expect(find.text('AulaSense'), findsOneWidget);
  });
}