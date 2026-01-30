import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carwash/features/entry/presentation/providers/active_vehicles_provider.dart';
import 'package:carwash/features/billing/presentation/providers/billing_provider.dart';

import 'package:carwash/features/home/presentation/screens/menu_screen.dart';
import 'package:quickalert/quickalert.dart';

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

      // Show Welcome Alert if user is admin and first login
      if (user != null &&
          user.role == 'admin' &&
          user.isFirstLogin == true &&
          mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.info,
          title: '¡Bienvenido!',
          text:
              'En el menú (tab), en la opción de Precios, puedes agregar los servicios y productos de tu Carwash.\n\nTambién puedes usar las ACCIONES RÁPIDAS en el menú para registrarlos más fácilmente.',
          confirmBtnText: 'Entendido',
          confirmBtnColor: const Color(0xFF1E88E5),
          onConfirmBtnTap: () async {
            Navigator.pop(context); // Close alert
            await context.read<AuthProvider>().markFirstLoginComplete();
          },
        );
      }
    });
  }

  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null) {
      // Refresh Active Vehicles (Counters)
      context.read<ActiveVehiclesProvider>().init(
        user.companyId,
        branchId: (user.branchId != null && user.branchId!.isNotEmpty)
            ? user.branchId
            : null,
        force:
            true, // Ensure force refresh if supported, or just init usually resets streams/listeners
      );
      // Refresh Billing (Counters)
      context.read<BillingProvider>().init(user.companyId, force: true);

      // Wait a bit to ensure UI updates if needed, though providers notify listeners.
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'CarwashPro',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: Drawer(
        elevation: 10,
        width: MediaQuery.of(context).size.width * 0.75, // Reasonable width
        child: MenuScreen(
          onItemClick: () {
            Navigator.pop(context); // Standard way to close drawer
          },
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _DashboardCard(
                  title: 'Ingreso\nVehículo',
                  icon: Icons.add_circle_rounded,
                  color: cardColors[2],
                  onTap: () => context.push('/vehicle-entry'),
                  isPrimary: true,
                ),
                _DashboardCard(
                  title: 'Vehículos\nActivos',
                  icon: Icons.local_car_wash_rounded,
                  color: cardColors[0], // Green
                  onTap: () => context.push('/active-vehicles'),
                  count: activeVehiclesCount,
                ),
                if (user?.role == 'admin')
                  _DashboardCard(
                    title: 'Facturación',
                    icon: Icons.check_circle_rounded,
                    color: cardColors[1], // Red
                    onTap: () => context.push('/billing-list'),
                    count: readyToBillCount,
                  ),
                if (user?.role == 'admin') ...[
                  _DashboardCard(
                    title: 'Sucursales',
                    icon: Icons.store_rounded,
                    color: cardColors[3],
                    onTap: () => context.push('/branch-list'),
                  ),
                  _DashboardCard(
                    title: 'Balance',
                    icon: Icons.account_balance_wallet_rounded,
                    color: cardColors[5],
                    onTap: () => context.push('/balance'),
                  ),
                  _DashboardCard(
                    title: 'Consultas',
                    icon: Icons.analytics_rounded,
                    color: cardColors[4], // Purple
                    onTap: () => context.push('/data-inspector'),
                  ),
                ],
              ],
            ),
          ),
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
                color: color.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
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
                    color: Colors.white.withValues(alpha: 0.15),
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
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 28, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15, // Reduced from 16
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
