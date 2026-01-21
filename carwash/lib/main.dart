import 'package:carwash/features/auth/presentation/screens/user_list_screen.dart';
import 'package:carwash/features/branch/presentation/screens/branch_list_screen.dart';
import 'package:carwash/features/entry/presentation/screens/active_vehicles_screen.dart';
import 'package:carwash/features/entry/presentation/screens/vehicle_entry_screen.dart';
import 'package:carwash/features/billing/presentation/providers/billing_provider.dart';
import 'package:carwash/features/billing/presentation/screens/billing_list_screen.dart';
import 'package:carwash/features/billing/presentation/screens/billing_process_screen.dart';
import 'package:carwash/features/billing/presentation/screens/balance_screen.dart';
import 'package:flutter/material.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart';
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
import 'features/entry/data/repositories/vehicle_entry_repository_impl.dart';
import 'features/branch/data/repositories/branch_repository_impl.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/company/domain/repositories/company_repository.dart';
import 'features/entry/domain/repositories/vehicle_entry_repository.dart';
import 'features/branch/domain/repositories/branch_repository.dart';

// Providers
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/company/presentation/providers/company_registration_provider.dart';
import 'features/entry/presentation/providers/vehicle_entry_provider.dart';
import 'features/branch/presentation/providers/branch_provider.dart';
import 'features/auth/presentation/providers/user_management_provider.dart';
import 'features/entry/presentation/providers/active_vehicles_provider.dart';

import 'core/utils/wash_types_seeder.dart';
import 'features/billing/domain/repositories/balance_repository.dart';
import 'features/billing/presentation/providers/balance_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Seed initial data for Wash Types (if empty)
  await WashTypesSeeder.seed();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Create Repository Instances
    final authRepository = AuthRepositoryImpl();
    final companyRepository = CompanyRepositoryImpl();
    final vehicleEntryRepository = VehicleEntryRepositoryImpl();
    final branchRepository = BranchRepositoryImpl();

    return MultiProvider(
      providers: [
        // Inject Repositories
        Provider<AuthRepository>.value(value: authRepository),
        Provider<CompanyRepository>.value(value: companyRepository),
        Provider<VehicleEntryRepository>.value(value: vehicleEntryRepository),
        Provider<BranchRepository>.value(value: branchRepository),

        // Inject ViewModels/Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: authRepository,
            companyRepository: companyRepository,
            branchRepository: branchRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CompanyRegistrationProvider(
            companyRepository: companyRepository,
            authRepository: authRepository,
            branchRepository: branchRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              VehicleEntryProvider(repository: vehicleEntryRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => BranchProvider(repository: branchRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => UserManagementProvider(
            authRepository: authRepository,
            branchRepository: branchRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ActiveVehiclesProvider(repository: vehicleEntryRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => BillingProvider(repository: vehicleEntryRepository),
        ),
        // Balance Feature
        Provider<BalanceRepository>(create: (_) => BalanceRepositoryImpl()),
        ChangeNotifierProvider(
          create: (context) =>
              BalanceProvider(repository: context.read<BalanceRepository>()),
        ),
      ],
      child: const AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.uri.toString() == '/login';
        final isRegistering = state.uri.toString() == '/register-company';

        if (!isLoggedIn && !isLoggingIn && !isRegistering) {
          return '/login';
        }

        if (isLoggedIn && (isLoggingIn || isRegistering)) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register-company',
          builder: (context, state) => const CompanyRegistrationScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/vehicle-entry',
          builder: (context, state) => const VehicleEntryScreen(),
        ),
        GoRoute(
          path: '/branch-list',
          builder: (context, state) => const BranchListScreen(),
        ),
        GoRoute(
          path: '/user-list',
          builder: (context, state) => const UserListScreen(),
        ),
        GoRoute(
          path: '/active-vehicles',
          builder: (context, state) => const ActiveVehiclesScreen(),
        ),
        GoRoute(
          path: '/billing-list',
          builder: (context, state) => const BillingListScreen(),
        ),
        GoRoute(
          path: '/billing-process',
          builder: (context, state) {
            final vehicle = state.extra as Vehicle;
            return BillingProcessScreen(vehicle: vehicle);
          },
        ),
        GoRoute(
          path: '/balance',
          builder: (context, state) => const BalanceScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'carwashPro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Enforce Light Mode
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Blue accent
          brightness: Brightness.light,
          surface: Colors.white,
          background: const Color(0xFFF9FAFB), // Very soft grey/white (Gray 50)
        ),
        scaffoldBackgroundColor: const Color(
          0xFFF9FAFB,
        ), // Consistent background
        useMaterial3: true,
        textTheme:
            GoogleFonts.outfitTextTheme(), // Use Outfit for a modern look (or Inter)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: Colors.white, // Fallback for card color
        // cardTheme: CardTheme(
        //   color: Colors.white,
        //   elevation: 2,
        //   shadowColor: Colors.black.withOpacity(0.05),
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(16),
        //     side: BorderSide(color: Colors.grey.shade100),
        //   ),
        //   margin: EdgeInsets.zero,
        // ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Removed darkTheme to force consistency
      routerConfig: router,
    );
  }
}
