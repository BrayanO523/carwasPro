import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/providers/vehicle_entry_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class VehicleEntryScreen extends StatelessWidget {
  const VehicleEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehicleEntryProvider>();
    final theme = Theme.of(context);

    // Get companyId from AuthProvider
    final authProvider = context.read<AuthProvider>();
    final companyId = authProvider.currentUser?.companyId;
    final branchId = authProvider.currentUser?.branchId; // Get branchId

    // Load Wash Types on Init
    // Ideally use State.initState but StatelessWidget needs PostFrameCallback or SideEffect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (companyId != null) {
        // Pass branchId (or empty if none, but ideally user has one)
        context.read<VehicleEntryProvider>().subscribeToWashTypes(
          companyId,
          branchId ?? '',
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso de Vehículo'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header: Cliente
            Text(
              'Datos del Cliente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: provider.nameController,
                    decoration: const InputDecoration(labelText: 'Nombre *'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: provider.lastNameController,
                    decoration: const InputDecoration(labelText: 'Apellido *'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: provider.phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 32),

            // Section Header: Vehículo
            Text(
              'Datos del Vehículo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: provider.modelController,
              decoration: const InputDecoration(
                labelText: 'Modelo del Vehículo *',
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Type Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Vehículo *',
              ),
              value: provider.selectedVehicleType,
              items: provider.vehicleTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setVehicleType(value);
                }
              },
            ),

            const SizedBox(height: 32),

            // Section Header: Servicios
            Text(
              'Servicios de Lavado',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Base Services (Radio)
            Text(
              'Lavado Base (Requerido)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...provider.washTypes.where((w) => w['categoria'] == 'base').map((
              service,
            ) {
              final priceMap = service['precios'] as Map<String, dynamic>?;
              final price = priceMap?[provider.selectedVehicleType] ?? 0;

              return RadioListTile<String>(
                title: Text(service['nombre']),
                subtitle: Text('L. ${price.toStringAsFixed(2)}'),
                value: service['id'],
                groupValue: provider.selectedBaseServiceId,
                onChanged: (value) {
                  if (value != null) provider.setBaseService(value);
                },
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
              );
            }),

            const SizedBox(height: 16),

            // Extra Services (Checkbox)
            if (provider.washTypes.any((w) => w['categoria'] == 'extra')) ...[
              Text(
                'Extras (Opcional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...provider.washTypes.where((w) => w['categoria'] == 'extra').map(
                (service) {
                  final priceMap = service['precios'] as Map<String, dynamic>?;
                  final price = priceMap?[provider.selectedVehicleType] ?? 0;
                  final id = service['id'];
                  final isSelected = provider.selectedExtrasIds.contains(id);

                  return CheckboxListTile(
                    title: Text(service['nombre']),
                    subtitle: Text('L. ${price.toStringAsFixed(2)}'),
                    value: isSelected,
                    onChanged: (_) => provider.toggleExtra(id),
                    contentPadding: EdgeInsets.zero,
                    activeColor: theme.colorScheme.primary,
                  );
                },
              ),
            ],

            const SizedBox(height: 32),

            // Section Header: Fotos
            Text(
              'Fotos (Estado Inicial)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Añada fotos de como llegó el vehículo (ANTES)',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Photos Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: provider.selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.selectedImages.length) {
                  // Add Button
                  return GestureDetector(
                    onTap: provider.pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                final image = provider.selectedImages[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(image, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => provider.removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 48),

            const SizedBox(height: 16),

            // SUMMARY CARD (Quote)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimado de Facturación',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Subtotal',
                    value: 'L. ${provider.subtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'ISV (15%)',
                    value: 'L. ${provider.isv.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'TOTAL',
                    value: 'L. ${provider.total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        if (companyId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Error: No se encontró la empresa del usuario',
                              ),
                            ),
                          );
                          return;
                        }
                        final currentUser = context
                            .read<AuthProvider>()
                            .currentUser;
                        final success = await provider.submitEntry(
                          companyId,
                          branchId: currentUser?.branchId,
                        );
                        if (success && context.mounted) {
                          provider.clearForm(); // Reset form
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vehículo ingresado con éxito'),
                            ),
                          );
                          context.pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(
                    0xFF4ADE80,
                  ), // Green like the dashboard card
                  foregroundColor: Colors.white,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Registrar Ingreso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black : Colors.grey[600],
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFF1E88E5) : Colors.black87,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
