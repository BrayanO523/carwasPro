import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.name ?? 'Usuario'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    title: 'Ingreso Vehículo',
                    icon: Icons.directions_car, // Coche llegando
                    color: Colors.green.shade500,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    title: 'Finalizar Lavado',
                    icon:
                        Icons.check_circle_outline, // Confirmación de terminado
                    color: Colors.red.shade500,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    title: '+ Vehículo',
                    icon: Icons.add_circle_outline,
                    color: Colors.blue.shade400,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    title: 'Sucursales',
                    icon: Icons.store_mall_directory,
                    color: Colors.orange.shade400,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    title: 'Usuarios',
                    icon: Icons.people,
                    color: Colors.purple.shade400,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    title: 'Balance',
                    icon: Icons.account_balance_wallet,
                    color: Colors.teal.shade400,
                    onTap: () {},
                  ),
                ],
              ),
            ),
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

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
