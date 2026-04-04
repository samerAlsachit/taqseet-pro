import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taqseet_pro/main.dart';
import 'package:taqseet_pro/core/database/database_helper.dart';
import 'package:taqseet_pro/core/network/api_client.dart';
import 'package:taqseet_pro/data/datasources/auth_datasource.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        sharedPreferences: await SharedPreferences.getInstance(),
        databaseHelper: DatabaseHelper(),
        apiClient: ApiClient(),
        authDataSource: AuthDataSource(
          ApiClient(),
          await SharedPreferences.getInstance(),
        ),
      ),
    );

    // Verify that the login screen is displayed
    expect(find.text('مرساة'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
