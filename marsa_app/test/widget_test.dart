import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marsa_app/screens/auth/auth_gate.dart';

void main() {
  testWidgets('Landing content renders brand elements', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingContent()));

    expect(find.text('مرساة'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('تفعيل كود'), findsOneWidget);
    expect(find.text('تجربة مجانية 14 يوم'), findsOneWidget);
    expect(find.byIcon(Icons.anchor), findsOneWidget);
  });
}
