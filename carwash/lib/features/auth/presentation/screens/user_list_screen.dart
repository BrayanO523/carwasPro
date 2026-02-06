import 'package:carwash/core/constants/app_permissions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_management_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyId = context.read<AuthProvider>().currentUser?.companyId;
      if (companyId != null) {
        context.read<UserManagementProvider>().loadConfig(companyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserManagementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton:
          context.read<AuthProvider>().hasPermission(AppPermissions.createUser)
          ? FloatingActionButton(
              onPressed: () => context.push('/user-form'),
              backgroundColor: const Color(0xFFA78BFA),
              child: const Icon(Icons.person_add_rounded, color: Colors.white),
            )
          : null,
      body: userProvider.isLoading && userProvider.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final companyId = context
                    .read<AuthProvider>()
                    .currentUser
                    ?.companyId;
                if (companyId != null) {
                  await userProvider.loadConfig(companyId, force: true);
                }
              },
              child: userProvider.users.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay usuarios registrados',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: userProvider.users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = userProvider.users[index];

                        String displayBranchName = 'Sucursal no encontrada';
                        try {
                          if (user.branchId != null &&
                              user.branchId!.isNotEmpty) {
                            if (userProvider.branches.isEmpty) {
                              displayBranchName = 'Cargando sucursales...';
                            } else {
                              try {
                                final branch = userProvider.branches.firstWhere(
                                  (b) => b.id == user.branchId,
                                );
                                displayBranchName = branch.name;
                              } catch (e) {
                                // Branch not found in the loaded list
                                displayBranchName =
                                    'Sucursal no encontrada (ID: ${user.branchId!.substring(0, 8)}...)';
                              }
                            }
                          } else {
                            displayBranchName = 'Sin Sucursal asignada';
                          }
                        } catch (_) {
                          displayBranchName = 'Error al cargar sucursal';
                        }

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFA78BFA,
                              ).withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFA78BFA),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                Text(
                                  displayBranchName,
                                  style: TextStyle(
                                    color: Colors.blueGrey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing:
                                context.read<AuthProvider>().hasPermission(
                                  AppPermissions.editUser,
                                )
                                ? const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  )
                                : null,
                            onTap:
                                context.read<AuthProvider>().hasPermission(
                                  AppPermissions.editUser,
                                )
                                ? () => context.push('/user-form', extra: user)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
