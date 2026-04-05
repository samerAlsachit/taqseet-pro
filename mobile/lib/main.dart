import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/network/api_client.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/installment_repository.dart';
import 'data/datasources/auth_datasource.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/customers_screen.dart';
import 'presentation/screens/products_screen.dart';
import 'presentation/screens/installments_screen.dart';
import 'presentation/providers/customer_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/installment_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // تهيئة قاعدة البيانات
  final databaseHelper = DatabaseHelper();

  // اختبار قاعدة البيانات
  try {
    await databaseHelper.database;
    debugPrint('✅ قاعدة البيانات جاهزة للاستخدام');

    // اختبار العمليات الأساسية
    final stats = await databaseHelper.getDatabaseStats();
    debugPrint('📊 إحصائيات قاعدة البيانات:');
    debugPrint('   العملاء: ${stats['customers']}');
    debugPrint('   المنتجات: ${stats['products']}');
    debugPrint('   خطط الأقساط: ${stats['installment_plans']}');
    debugPrint('   الدفعات: ${stats['payments']}');
  } catch (e) {
    debugPrint('❌ خطأ في تهيئة قاعدة البيانات: $e');
  }

  // تهيئة API Client
  final apiClient = ApiClient();

  // تهيئة Auth DataSource
  final authDataSource = AuthDataSource(apiClient, sharedPreferences);

  // تهيئة المصادقة
  await authDataSource.initializeAuth();

  runApp(
    MyApp(
      sharedPreferences: sharedPreferences,
      databaseHelper: databaseHelper,
      apiClient: apiClient,
      authDataSource: authDataSource,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final DatabaseHelper databaseHelper;
  final ApiClient apiClient;
  final AuthDataSource authDataSource;

  const MyApp({
    super.key,
    required this.sharedPreferences,
    required this.databaseHelper,
    required this.apiClient,
    required this.authDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => CustomerProvider(CustomerRepository(databaseHelper)),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductRepository(databaseHelper)),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              InstallmentProvider(InstallmentRepository(databaseHelper)),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // إعدادات اللغة والاتجاه
            locale: const Locale('ar', 'IQ'),
            supportedLocales: const [Locale('ar', 'IQ')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              return const Locale('ar', 'IQ');
            },

            // إعدادات الثيم
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // إعدادات النظام
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                ),
              );
            },

            home: const LoginScreen(),
            routes: {
              AppConstants.loginRoute: (context) => const LoginScreen(),
              AppConstants.dashboardRoute: (context) => const DashboardScreen(),
              AppConstants.customersRoute: (context) => const CustomersScreen(),
              AppConstants.productsRoute: (context) => const ProductsScreen(),
              AppConstants.installmentsRoute: (context) =>
                  const InstallmentsScreen(),
            },
          );
        },
      ),
    );
  }
}
