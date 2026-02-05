import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/active_vehicles_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart';
// import 'package:url_launcher/url_launcher.dart'; // Removed: Moved to Provider

import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'package:quickalert/quickalert.dart';

class ActiveVehiclesScreen extends StatefulWidget {
  const ActiveVehiclesScreen({super.key});

  @override
  State<ActiveVehiclesScreen> createState() => _ActiveVehiclesScreenState();
}

class _ActiveVehiclesScreenState extends State<ActiveVehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AuthProvider>().currentUser;
      final companyId = currentUser?.companyId;
      if (companyId != null) {
        context.read<ActiveVehiclesProvider>().init(
          companyId,
          branchId: currentUser?.branchId,
        );
      }
    });

    _searchController.addListener(() {
      context.read<ActiveVehiclesProvider>().setSearchText(
        _searchController.text,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveVehiclesProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Vehículos en Proceso',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o placa...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await provider.refresh();
                    },
                    child: provider.vehicles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_car_outlined,
                                      size: 64,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay vehículos',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.push('/vehicle-entry'),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Agregar Vehículo'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.vehicles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final vehicle = provider.vehicles[index];
                              return _VehicleCard(vehicle: vehicle);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showVehicleDetails(context, vehicle);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image Thumbnail (or Placeholder)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: vehicle.photoUrls.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            vehicle.photoUrls.first,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vehicle.photoUrls.isEmpty
                    ? const Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (vehicle.brand ?? 'Vehículo').trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.clientName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (vehicle.plate != null && vehicle.plate!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Text(
                              vehicle.plate!,
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        _StatusChip(status: vehicle.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (context.read<AuthProvider>().currentUser?.role ==
                        'admin')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.confirm,
                              title: '¿Terminar Lavado?',
                              text:
                                  '¿El vehículo ${vehicle.brand ?? ''} está listo para facturar?',
                              confirmBtnText: 'Sí',
                              cancelBtnText: 'Cancelar',
                              confirmBtnColor: Colors.green,
                              onConfirmBtnTap: () async {
                                Navigator.pop(context); // Close Alert
                                try {
                                  final companyName =
                                      context
                                          .read<AuthProvider>()
                                          .companyName ??
                                      'CarWash';
                                  final currentUser = context
                                      .read<AuthProvider>()
                                      .currentUser;
                                  await context
                                      .read<ActiveVehiclesProvider>()
                                      .completeWashAndNotify(
                                        vehicle: vehicle,
                                        companyName: companyName,
                                        userId: currentUser?.id,
                                        userEmail: currentUser?.email,
                                      );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Vehículo marcado como lavado y notificado',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;

                                  String message = 'Error: $e';
                                  Color color = Colors.red;

                                  if (e is NoPhoneException) {
                                    message =
                                        'El cliente no tiene teléfono registrado';
                                  } else if (e is WhatsAppLaunchException) {
                                    message =
                                        'Esta persona no tiene WhatsApp (o el número es incorrecto)';
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: color,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Terminar y Avisar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green[800],
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Image Carousel or Grid
              if (vehicle.photoUrls.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: vehicle.photoUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageViewer(
                                photoUrls: vehicle.photoUrls,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: vehicle.photoUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (vehicle.brand ?? 'Vehículo').trim(),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Cliente',
                      value: vehicle.clientName,
                    ),
                    if (vehicle.plate != null)
                      _InfoRow(
                        icon: Icons.confirmation_number,
                        label: 'Placa',
                        value: vehicle.plate!,
                      ),
                    if (vehicle.color != null)
                      _InfoRow(
                        icon: Icons.color_lens,
                        label: 'Color',
                        value: vehicle.color!,
                      ),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Ingreso',
                      value: vehicle.entryDate.toString().split('.')[0],
                    ),
                    const SizedBox(height: 20),
                    if (vehicle.services.isNotEmpty) ...[
                      const Text(
                        'Servicios',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: vehicle.services
                            .map((s) => _ServiceChip(serviceId: s))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String text = status;

    if (status == 'pending') {
      color = Colors.orange;
      text = 'Pendiente';
    } else if (status == 'washing') {
      color = Colors.blue;
      text = 'Lavando';
    } else if (status == 'washed') {
      color = Colors.teal;
      text = 'Listo p/ Facturar';
    } else if (status == 'finished') {
      color = Colors.green;
      text = 'Entregado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String serviceId;

  const _ServiceChip({required this.serviceId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveVehiclesProvider>();
    final name = provider.getServiceName(serviceId);

    return Chip(
      label: Text(name),
      backgroundColor: Colors.purple[50],
      labelStyle: TextStyle(color: Colors.purple[900]),
    );
  }
}
