import 'package:carwash/features/auth/presentation/screens/user_list_screen.dart';
import 'package:carwash/features/auth/presentation/screens/user_create_screen.dart';
import 'package:carwash/features/branch/presentation/screens/branch_list_screen.dart';
import 'package:carwash/features/branch/presentation/screens/branch_create_screen.dart';
import 'package:carwash/features/entry/presentation/screens/active_vehicles_screen.dart';
import 'package:carwash/features/entry/presentation/screens/vehicle_entry_screen.dart';
import 'package:carwash/features/billing/presentation/providers/billing_provider.dart';
import 'package:carwash/features/billing/presentation/screens/billing_list_screen.dart';
import 'package:carwash/features/billing/presentation/screens/billing_process_screen.dart';
import 'package:carwash/features/billing/presentation/screens/balance_screen.dart';
import 'package:carwash/features/billing/presentation/screens/accounts_receivable_screen.dart'; // NEW
import 'package:carwash/features/company/presentation/screens/company_config_screen.dart';
import 'package:carwash/features/entry/presentation/screens/client_list_screen.dart'; // NEW
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
import 'features/home/presentation/screens/data_inspector_screen.dart';

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
import 'features/home/presentation/providers/data_inspector_provider.dart';

// import 'core/utils/wash_types_seeder.dart'; // Removed
import 'features/billing/domain/repositories/balance_repository.dart';
import 'features/billing/presentation/providers/balance_provider.dart';

import 'features/wash_types/data/repositories/wash_type_repository_impl.dart';
import 'features/wash_types/domain/repositories/wash_type_repository.dart';
import 'features/wash_types/presentation/providers/wash_type_provider.dart';
import 'features/wash_types/presentation/screens/wash_type_list_screen.dart';
import 'features/wash_types/presentation/screens/wash_type_form_screen.dart';
import 'features/wash_types/domain/entities/wash_type.dart';

import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/repositories/product_repository.dart';
import 'features/products/presentation/providers/product_provider.dart';
import 'features/products/presentation/screens/product_form_screen.dart';
import 'features/products/domain/entities/product.dart';

import 'features/audit/data/repositories/audit_repository_impl.dart';
import 'features/audit/domain/repositories/audit_repository.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize standard date formatting for Spanish
  await initializeDateFormatting('es', null);

  // Seeding is now handled by legacy migration or admin tools, not on every app start.
  // await WashTypesSeeder.seed();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Create Repository Instances
    final auditRepository = AuditRepositoryImpl();
    final authRepository = AuthRepositoryImpl(auditRepository: auditRepository);
    final companyRepository = CompanyRepositoryImpl();
    final vehicleEntryRepository = VehicleEntryRepositoryImpl(
      auditRepository: auditRepository,
    );
    final branchRepository = BranchRepositoryImpl(
      auditRepository: auditRepository,
    );
    final washTypeRepository = WashTypeRepositoryImpl();
    final productRepository = ProductRepositoryImpl();

    return MultiProvider(
      providers: [
        // Inject Repositories
        Provider<AuthRepository>.value(value: authRepository),
        Provider<CompanyRepository>.value(value: companyRepository),
        Provider<VehicleEntryRepository>.value(value: vehicleEntryRepository),
        Provider<BranchRepository>.value(value: branchRepository),
        Provider<WashTypeRepository>.value(value: washTypeRepository),
        Provider<AuditRepository>.value(value: auditRepository),

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
            washTypeRepository: washTypeRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VehicleEntryProvider(
            repository: vehicleEntryRepository,
            washTypeRepository: washTypeRepository,
            branchRepository: branchRepository,
          ),
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
        // Balance Feature
        Provider<BalanceRepository>(create: (_) => BalanceRepositoryImpl()),
        ChangeNotifierProvider(
          create: (context) =>
              BalanceProvider(repository: context.read<BalanceRepository>()),
        ),

        // Billing Feature (Depends on VehicleEntryRepo and BalanceRepo)
        ChangeNotifierProvider(
          create: (context) => BillingProvider(
            repository: vehicleEntryRepository,
            balanceRepository: context.read<BalanceRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => WashTypeProvider(repository: washTypeRepository),
        ),

        // Products Feature
        Provider<ProductRepository>.value(value: productRepository),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(repository: productRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => DataInspectorProvider(
            companyRepository: companyRepository,
            branchRepository: branchRepository,
            authRepository: authRepository,
            vehicleRepository: vehicleEntryRepository,
            washTypeRepository: washTypeRepository,
            productRepository: productRepository,
            auditRepository: auditRepository,
          ),
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
        GoRoute(
          path: '/company-config',
          builder: (context, state) => const CompanyConfigScreen(),
        ),
        GoRoute(
          path: '/wash-types',
          builder: (context, state) => const WashTypeListScreen(),
        ),
        GoRoute(
          path: '/wash-types/add',
          builder: (context, state) => const WashTypeFormScreen(),
        ),
        GoRoute(
          path: '/wash-types/edit',
          builder: (context, state) {
            final washType = state.extra as WashType;
            return WashTypeFormScreen(washType: washType);
          },
        ),
        GoRoute(
          path: '/products/add',
          builder: (context, state) => const ProductFormScreen(),
        ),
        GoRoute(
          path: '/products/edit',
          builder: (context, state) {
            final product = state.extra as Product;
            return ProductFormScreen(product: product);
          },
        ),
        GoRoute(
          path: '/branch-create',
          builder: (context, state) => const BranchCreateScreen(),
        ),
        GoRoute(
          path: '/user-create',
          builder: (context, state) => const UserCreateScreen(),
        ),
        GoRoute(
          path: '/data-inspector',
          builder: (context, state) => const DataInspectorScreen(),
        ),
        GoRoute(
          path: '/client-list',
          builder: (context, state) => const ClientListScreen(),
        ),
        GoRoute(
          path: '/accounts-receivable',
          builder: (context, state) => const AccountsReceivableScreen(),
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
