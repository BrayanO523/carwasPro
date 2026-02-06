import 'package:carwash/core/constants/app_permissions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'branch_fiscal_config_screen.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final branchProvider = context.watch<BranchProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucursales'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton:
          authProvider.hasPermission(AppPermissions.manageBranches)
          ? FloatingActionButton(
              onPressed: () => context.push('/branch-create'),
              backgroundColor: const Color(
                0xFFFBBF24,
              ), // Amber color matching home card
              child: const Icon(
                Icons.add_business_rounded,
                color: Colors.white,
              ),
            )
          : null,
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
                            onTap:
                                authProvider.hasPermission(
                                  AppPermissions.manageBranches,
                                )
                                ? () {
                                    final companyId = context
                                        .read<AuthProvider>()
                                        .currentUser
                                        ?.companyId;
                                    if (companyId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BranchFiscalConfigScreen(
                                                companyId: companyId,
                                                branch: branch,
                                              ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFFBBF24,
                              ).withValues(alpha: 0.2),
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
