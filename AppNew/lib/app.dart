import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/config/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/blocs/auth_bloc/auth_bloc.dart';
import 'presentation/blocs/dashboard_bloc/dashboard_bloc.dart';
import 'presentation/blocs/customer_bloc/customer_bloc.dart';
import 'presentation/blocs/product_bloc/product_bloc.dart';
import 'presentation/blocs/installment_bloc/installment_bloc.dart';
import 'presentation/blocs/payment_bloc/payment_bloc.dart';
import 'presentation/blocs/cash_sale_bloc/cash_sale_bloc.dart';
import 'presentation/screens/landing/splash_screen.dart';
import 'presentation/screens/landing/landing_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/activate_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/main/main_shell.dart';
import 'presentation/screens/customers/customers_screen.dart';
import 'presentation/screens/customers/customer_form_screen.dart';
import 'presentation/screens/customers/customer_detail_screen.dart';
import 'presentation/screens/products/products_screen.dart';
import 'presentation/screens/products/product_form_screen.dart';
import 'presentation/screens/installments/installments_screen.dart';
import 'presentation/screens/installments/installment_form_screen.dart';
import 'presentation/screens/installments/installment_detail_screen.dart';
import 'presentation/screens/shared/payment_screen.dart';

class MarsaApp extends StatelessWidget {
  const MarsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => AuthBloc()),
              BlocProvider(create: (_) => DashboardBloc()),
              BlocProvider(create: (_) => CustomerBloc()),
              BlocProvider(create: (_) => ProductBloc()),
              BlocProvider(create: (_) => InstallmentBloc()),
              BlocProvider(create: (_) => PaymentBloc()),
              BlocProvider(create: (_) => CashSaleBloc()),
            ],
            child: MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: const Locale('ar', 'IQ'),
              supportedLocales: const [Locale('ar', 'IQ')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthInitial) return const SplashScreen();
                  if (state is AuthLoading) return const SplashScreen();
                  if (state is AuthAuthenticated) return const MainShell();
                  if (state is AuthUnauthenticated) return const LandingScreen();
                  if (state is AuthError) return const LandingScreen();
                  return const LandingScreen();
                },
              ),
              routes: {
                '/login': (_) => const LoginScreen(),
                '/activate': (_) => const ActivateScreen(),
                '/register': (_) => const RegisterScreen(),
                '/home': (_) => const MainShell(),
                '/customers': (_) => const CustomersScreen(),
                '/customers/new': (_) => const CustomerFormScreen(),
                '/products': (_) => const ProductsScreen(),
                '/products/new': (_) => const ProductFormScreen(),
                '/installments': (_) => const InstallmentsScreen(),
                '/installments/new': (_) => const InstallmentFormScreen(),
                '/payment': (_) => const PaymentScreen(),
              },
              onGenerateRoute: (settings) {
                final uri = Uri.parse(settings.name ?? '');
                final segments = uri.pathSegments;

                if (segments.length == 2 && segments[0] == 'customers') {
                  return MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: segments[1]));
                }
                if (segments.length == 2 && segments[0] == 'products') {
                  return MaterialPageRoute(builder: (_) => ProductFormScreen(productId: segments[1]));
                }
                if (segments.length == 2 && segments[0] == 'installments') {
                  return MaterialPageRoute(builder: (_) => InstallmentDetailScreen(installmentId: segments[1]));
                }
                return MaterialPageRoute(builder: (_) => const LandingScreen());
              },
            ),
          );
        },
      ),
    );
  }
}
