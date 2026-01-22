import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/wash_type_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';

class WashTypeListScreen extends StatefulWidget {
  const WashTypeListScreen({super.key});

  @override
  State<WashTypeListScreen> createState() => _WashTypeListScreenState();
}

class _WashTypeListScreenState extends State<WashTypeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final companyId = authProvider.currentUser?.companyId ?? '';
      context.read<WashTypeProvider>().loadWashTypes(companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WashTypeProvider>();
    final washTypes = provider.washTypes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración de Precios',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/wash-types/add'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final authProvider = context.read<AuthProvider>();
                final companyId = authProvider.currentUser?.companyId ?? '';
                await provider.loadWashTypes(companyId, force: true);
              },
              child: washTypes.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('No hay servicios configurados'),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () async {
                                    final authProvider = context
                                        .read<AuthProvider>();
                                    final companyId =
                                        authProvider.currentUser?.companyId ??
                                        '';
                                    final branchId = authProvider
                                        .currentUser
                                        ?.branchId; // Try to get from User

                                    if (branchId != null) {
                                      await provider.seedDefaultCatalog(
                                        companyId,
                                        branchId,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No se puede cargar: Usuario sin sucursal asignada',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cloud_download),
                                  label: const Text('Cargar Catálogo Inicial'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: washTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = washTypes[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () =>
                                context.push('/wash-types/edit', extra: item),
                            leading: CircleAvatar(
                              backgroundColor: item.category == 'base'
                                  ? Colors.blue[50]
                                  : Colors.purple[50],
                              child: Icon(
                                item.category == 'base'
                                    ? Icons.local_car_wash
                                    : Icons.star,
                                color: item.category == 'base'
                                    ? Colors.blue
                                    : Colors.purple,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _PriceChip(
                                      label: 'Moto',
                                      price: item.prices['moto'],
                                    ),
                                    _PriceChip(
                                      label: 'Turismo',
                                      price: item.prices['turismo'],
                                    ),
                                    _PriceChip(
                                      label: 'Camioneta',
                                      price: item.prices['camioneta'],
                                    ),
                                    _PriceChip(
                                      label: 'Grande',
                                      price: item.prices['grande'],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: item.isActive
                                      ? Colors.green
                                      : Colors.grey,
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
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double? price;

  const _PriceChip({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    if (price == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        '$label: L.${price!.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 10, color: Colors.grey[800]),
      ),
    );
  }
}
