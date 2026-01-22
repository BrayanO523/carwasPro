import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyId = context.read<AuthProvider>().currentUser?.companyId;
      if (companyId != null) {
        context.read<BranchProvider>().loadBranches(companyId);
      }
    });
  }

  void _showAddBranchDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final companyId = context.read<AuthProvider>().currentUser?.companyId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Sucursal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (companyId != null &&
                  nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty) {
                final success = await context.read<BranchProvider>().addBranch(
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = context.watch<BranchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucursales'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBranchDialog(context),
        backgroundColor: const Color(
          0xFFFBBF24,
        ), // Amber color matching home card
        child: const Icon(Icons.add_business_rounded, color: Colors.white),
      ),
      body: branchProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final companyId = context
                    .read<AuthProvider>()
                    .currentUser
                    ?.companyId;
                if (companyId != null) {
                  await branchProvider.loadBranches(companyId, force: true);
                }
              },
              child: branchProvider.branches.isEmpty
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
                                  Icons.store_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay sucursales registradas',
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
                      itemCount: branchProvider.branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final branch = branchProvider.branches[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFFBBF24,
                              ).withOpacity(0.2),
                              child: const Icon(
                                Icons.store_rounded,
                                color: Color(0xFFFBBF24),
                              ),
                            ),
                            title: Text(
                              branch.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(branch.address),
                                if (branch.phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    branch.phone,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
