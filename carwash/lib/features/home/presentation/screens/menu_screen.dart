import 'package:carwash/core/constants/app_permissions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback onItemClick;

  const MenuScreen({super.key, required this.onItemClick});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SafeArea(
        // Ensure content is safe from status bar
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Company Info
                    if (authProvider.companyName != null)
                      Text(
                        authProvider.companyName!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (authProvider.branchName != null)
                      Row(
                        children: [
                          Icon(
                            Icons.store_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            authProvider.branchName!,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 30),

                    // User Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueGrey[700],
                            radius: 20,
                            child: Text(
                              user?.name.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Usuario',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                user?.role == 'admin'
                                    ? 'Administrador'
                                    : 'Empleado',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Menu Options
                    if (authProvider.hasPermission(AppPermissions.viewClients))
                      _MenuItem(
                        title: 'Gestión de Clientes',
                        icon: Icons.people_outline_rounded,
                        color: Colors.blue.shade600,
                        onTap: () {
                          onItemClick();
                          context.push('/client-list');
                        },
                      ),
                    if (authProvider.hasPermission(AppPermissions.viewBilling))
                      _MenuItem(
                        title: 'Cuentas por Cobrar',
                        icon: Icons.request_quote_rounded,
                        color: Colors.teal.shade600,
                        onTap: () {
                          onItemClick();
                          context.push('/accounts-receivable');
                        },
                      ),
                    const SizedBox(height: 10),
                    if (authProvider.hasPermission(AppPermissions.viewUsers))
                      _MenuItem(
                        title: 'Usuarios',
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFFA78BFA),
                        onTap: () {
                          onItemClick();
                          context.push('/user-list');
                        },
                      ),
                    if (authProvider.hasPermission(AppPermissions.viewSettings))
                      _MenuItem(
                        title: 'Empresa',
                        icon: Icons.business_rounded,
                        color: const Color(0xFF6366F1),
                        onTap: () {
                          onItemClick();
                          context.push('/company-config');
                        },
                      ),
                    if (authProvider.hasPermission(
                      AppPermissions.viewInventory,
                    ))
                      _MenuItem(
                        title: 'Precios (Servicios)',
                        icon: Icons.attach_money_rounded,
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          onItemClick();
                          context.push('/wash-types');
                        },
                      ),
                    const Divider(height: 30),

                    // Quick Actions
                    if (authProvider.hasPermission(
                      AppPermissions.createInventory,
                    )) ...[
                      Text(
                        'ACCIONES RÁPIDAS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MenuItem(
                        title: 'Registrar Servicio',
                        icon: Icons.add_circle_outline_rounded,
                        color: Colors.orange,
                        onTap: () {
                          onItemClick();
                          context.push('/wash-types/add');
                        },
                      ),
                      _MenuItem(
                        title: 'Registrar Producto',
                        icon: Icons.add_box_outlined,
                        color: Colors.teal,
                        onTap: () {
                          onItemClick();
                          context.push('/products/add');
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Logout (Fixed at bottom)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _MenuItem(
                title: 'Cerrar Sesión',
                icon: Icons.logout_rounded,
                color: Colors.red[400]!,
                onTap: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}
