import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/company/presentation/screens/company_registration_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

// Repositories
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/company/data/repositories/company_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/company/domain/repositories/company_repository.dart';

// Providers
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/company/presentation/providers/company_registration_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register-company',
      builder: (context, state) => const CompanyRegistrationScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Create Repository Instances
    final authRepository = AuthRepositoryImpl();
    final companyRepository = CompanyRepositoryImpl();

    return MultiProvider(
      providers: [
        // Inject Repositories (Optional, if you want to access them directly, otherwise just inject into Providers)
        Provider<AuthRepository>.value(value: authRepository),
        Provider<CompanyRepository>.value(value: companyRepository),

        // Inject ViewModels/Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CompanyRegistrationProvider(
            companyRepository: companyRepository,
            authRepository: authRepository,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Carwash App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5), // Blue accent
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white10,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
