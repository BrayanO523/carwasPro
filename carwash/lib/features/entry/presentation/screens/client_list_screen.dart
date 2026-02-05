import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import '../../domain/entities/client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'client_form_screen.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final companyId = context.read<AuthProvider>().currentUser?.companyId;

    if (companyId == null) {
      return const Center(child: Text('Error: No Company ID'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Clientes',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Client>>(
        stream: context.read<VehicleEntryRepository>().getClientsStream(
          companyId,
          branchId: context.read<AuthProvider>().currentUser?.branchId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = snapshot.data!;
          if (clients.isEmpty) {
            return const Center(child: Text('No hay clientes registrados'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final client = clients[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    client.fullName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.phone),
                      if (client.creditEnabled)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Crédito: Activo',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '|  Límite: L. ${client.creditLimit.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientFormScreen(client: client),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
