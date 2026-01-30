import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserManagementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/user-create'),
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
    final emissionPointController = TextEditingController(
      text: user.emissionPoint ?? '001',
    );
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
                  if (user.role == 'admin')
                    TextField(
                      controller: emissionPointController,
                      decoration: const InputDecoration(
                        labelText: 'Punto de Emisión (SAR)',
                      ),
                      maxLength: 3,
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Sucursal'),
                    initialValue: selectedBranchId,
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
                      // Force null if not admin, otherwise use controller value
                      emissionPoint: user.role == 'admin'
                          ? emissionPointController.text.trim()
                          : null,
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
