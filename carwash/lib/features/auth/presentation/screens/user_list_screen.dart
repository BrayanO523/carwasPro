import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_management_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';

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

  void _showAddUserDialog(BuildContext context) {
    final provider = context.read<UserManagementProvider>();
    final companyId = context.read<AuthProvider>().currentUser?.companyId;

    showDialog(
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: Builder(
          builder: (context) {
            final localProvider = context.watch<UserManagementProvider>();
            return AlertDialog(
              title: const Text('Nuevo Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: localProvider.nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: localProvider.emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: localProvider.passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Rol'),
                      value: localProvider.selectedRole,
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Empleado'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          localProvider.setSelectedRole(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Sucursal'),
                      value: localProvider.selectedBranchId,
                      items: localProvider.branches.map((branch) {
                        return DropdownMenuItem(
                          value: branch.id,
                          child: Text(branch.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        localProvider.setSelectedBranch(value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                if (localProvider.errorMessage != null)
                  Text(
                    localProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ElevatedButton(
                  onPressed: localProvider.isLoading
                      ? null
                      : () async {
                          if (companyId != null) {
                            final success = await localProvider.createUser(
                              companyId: companyId,
                            );
                            if (success && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          }
                        },
                  child: localProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserManagementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: const Color(
          0xFFA78BFA,
        ), // Purple color matching home card
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
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
                            onTap: () => _showEditUserDialog(context, user),
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFA78BFA,
                              ).withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFFA78BFA),
                              ),
                            ),
                            title: Text(user.name ?? user.email),
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
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserEntity user) {
    final provider = context.read<UserManagementProvider>();
    final companyId = context.read<AuthProvider>().currentUser?.companyId;
    final nameController = TextEditingController(text: user.name);
    String? selectedBranchId = user.branchId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Usuario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Sucursal'),
                    value: selectedBranchId,
                    items: provider.branches.map((branch) {
                      return DropdownMenuItem(
                        value: branch.id,
                        child: Text(branch.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBranchId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Delete Confirmation
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Eliminar Usuario'),
                      content: const Text(
                        '¿Estás seguro de que deseas eliminar este usuario?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && companyId != null && ctx.mounted) {
                    final success = await provider.deleteUser(
                      userId: user.id,
                      companyId: companyId,
                    );
                    if (success && ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (companyId != null) {
                    final success = await provider.updateUser(
                      userId: user.id,
                      name: nameController.text.trim(),
                      branchId: selectedBranchId,
                      companyId: companyId,
                    );
                    if (success && ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
