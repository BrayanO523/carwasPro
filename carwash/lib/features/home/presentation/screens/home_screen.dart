import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carwash/features/entry/presentation/providers/active_vehicles_provider.dart';
import 'package:carwash/features/billing/presentation/providers/billing_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers to fetch counts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      if (user != null) {
        context.read<ActiveVehiclesProvider>().init(
          user.companyId,
          branchId: (user.branchId != null && user.branchId!.isNotEmpty)
              ? user.branchId
              : null,
        );
        context.read<BillingProvider>().init(user.companyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    // Modern Color Palette
    final cardColors = [
      const Color(0xFF4ADE80), // Green for Ingreso (Softer, vibrant)
      const Color(0xFFF87171), // Red for Finalizar (Softer)
      const Color(0xFF60A5FA), // Blue for New Vehicle
      const Color(0xFFFBBF24), // Amber for Branches
      const Color(0xFFA78BFA), // Purple for Users
      const Color(0xFF2DD4BF), // Teal for Balance
    ];

    final activeVehiclesCount = context
        .watch<ActiveVehiclesProvider>()
        .vehicles
        .length;
    final readyToBillCount = context.watch<BillingProvider>().vehicles.length;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey/white background
      appBar: AppBar(
        // ... (AppBar content unchanged)
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (authProvider.companyName != null)
                    Text(
                      authProvider.companyName!.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (authProvider.branchName != null)
                    Text(
                      authProvider.branchName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user?.name.split(' ').first.toUpperCase() ?? 'USUARIO',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              color: Colors.red[400],
              tooltip: 'Cerrar Sesión',
              onPressed: () {
                context.read<AuthProvider>().logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0, // Square cards
          children: [
            _DashboardCard(
              title: 'Vehículos\nActivos',
              icon: Icons.local_car_wash_rounded,
              color: cardColors[0],
              onTap: () => context.push('/active-vehicles'),
              isPrimary: true,
              count: activeVehiclesCount,
            ),
            _DashboardCard(
              title: 'Finalizar\nLavado',
              icon: Icons.check_circle_rounded,
              color: cardColors[1],
              onTap: () => context.push('/billing-list'),
              count: readyToBillCount,
            ),
            _DashboardCard(
              title: 'Ingreso\nVehículo',
              icon: Icons.add_circle_rounded,
              color: cardColors[2],
              onTap: () => context.push('/vehicle-entry'),
            ),
            if (user?.role == 'admin') ...[
              _DashboardCard(
                title: 'Sucursales',
                icon: Icons.store_rounded,
                color: cardColors[3],
                onTap: () => context.push('/branch-list'),
              ),
              _DashboardCard(
                title: 'Usuarios',
                icon: Icons.people_alt_rounded,
                color: cardColors[4],
                onTap: () => context.push('/user-list'),
              ),
              _DashboardCard(
                title: 'Balance',
                icon: Icons.account_balance_wallet_rounded,
                color: cardColors[5],
                onTap: () => context.push('/balance'),
              ),
              _DashboardCard(
                title: 'Empresa\n(SAR)',
                icon: Icons.business_rounded,
                color: const Color(0xFF6366F1), // Indigo
                onTap: () => context.push('/company-config'),
              ),
              _DashboardCard(
                title: 'Precios\n(Servicios)',
                icon: Icons.attach_money_rounded,
                color: const Color(0xFFEC4899), // Pink
                onTap: () => context.push('/wash-types'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;
  final int count;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.8)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circle in background
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 32, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (count > 0)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: GoogleFonts.outfit(
                        color: color, // Use card color for text
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
