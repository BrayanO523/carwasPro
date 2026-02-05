import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import '../providers/billing_provider.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AuthProvider>().currentUser;
      final companyId = currentUser?.companyId;
      if (companyId != null) {
        context.read<BillingProvider>().init(
          companyId,
          branchId:
              (currentUser?.branchId != null &&
                  currentUser!.branchId!.isNotEmpty)
              ? currentUser.branchId
              : null,
        );
      }
    });

    _searchController.addListener(() {
      context.read<BillingProvider>().setSearchText(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillingProvider>();
    final vehicles = provider.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Facturación',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o placa...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Vehicle List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await provider.refresh();
                    },
                    child: vehicles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay vehículos para facturar',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = vehicles[index];
                              return _BillingVehicleCard(vehicle: vehicle);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BillingVehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const _BillingVehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          context.push('/billing-process', extra: vehicle);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image Thumbnail
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
                    ? const Icon(Icons.directions_car, color: Colors.grey)
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[100]!),
                      ),
                      child: Text(
                        'Por Cobrar',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
