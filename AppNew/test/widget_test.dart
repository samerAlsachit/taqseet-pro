import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marsa_app/app.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MarsaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });
}
