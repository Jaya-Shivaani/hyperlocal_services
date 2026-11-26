import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/provider_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HyperLocalApp());
}

class HyperLocalApp extends StatelessWidget {
  const HyperLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'HyperLocal Services',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoggedIn) {
              if (auth.userType == 'admin') return const AdminDashboardScreen();
              if (auth.userType == 'provider') return const ProviderDashboardScreen();
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/home': (ctx) => const HomeScreen(),
          '/admin': (ctx) => const AdminDashboardScreen(),
          '/provider': (ctx) => const ProviderDashboardScreen(),
        },
      ),
    );
  }
}
