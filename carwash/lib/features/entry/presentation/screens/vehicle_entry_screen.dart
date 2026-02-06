import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/providers/vehicle_entry_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/client.dart'; // Added Import

import '../../domain/entities/vehicle.dart'; // Ensure Import

class VehicleEntryScreen extends StatefulWidget {
  final Vehicle? vehicle; // Added optional vehicle param

  const VehicleEntryScreen({super.key, this.vehicle});

  @override
  State<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends State<VehicleEntryScreen> {
  int _currentStep = 0;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void dispose() {
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load Wash Types on Init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VehicleEntryProvider>();
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      // Clear previous form data to avoid stale state
      provider.clearForm();

      if (currentUser?.companyId != null) {
        if (currentUser!.role == 'admin') {
          provider.loadBranches(currentUser.companyId);
        }

        final branchId = widget.vehicle?.branchId ?? currentUser.branchId ?? '';

        provider.subscribeToWashTypes(currentUser.companyId, branchId);
        provider.subscribeToClients(currentUser.companyId, branchId);

        // Initialize for Edit if vehicle provided
        if (widget.vehicle != null) {
          provider.setVehicle(widget.vehicle!);
        }
      }
    });
  }

  // ... (methods _getVehicleIcon, _nextStep, _prevStep remain same)

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'moto':
        return Icons.two_wheeler;
      case 'trimoto':
        return Icons.electric_bike; // Close enough
      case 'turismo':
        return Icons.directions_car;
      case 'camioneta':
        return Icons.time_to_leave; // SUV
      case 'pick up':
      case 'pick_up':
        return Icons.local_shipping_outlined; // Small truck
      case 'microbus':
        return Icons.airport_shuttle;
      case 'camion':
        return Icons.local_shipping;
      case 'autobus':
        return Icons.directions_bus;
      case 'cabezal':
        return Icons.front_loader; // Or local_shipping
      default:
        return Icons.category;
    }
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 3) _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerRead = context.read<VehicleEntryProvider>();
    final providerWatch = context.watch<VehicleEntryProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isEmployee = currentUser?.role != 'admin';

    // Steps definition
    final steps = [
      _buildStep(
        index: 0,
        title: 'Datos del Cliente',
        isActive: _currentStep == 0,
        isCompleted: _currentStep > 0,
        summary: providerWatch.nameController.text.isNotEmpty
            ? providerWatch.nameController.text
            : null,
        content: Column(
          children: [
            // Branch selection removed per user request (Auto-assigned)
            RawAutocomplete<Client>(
              textEditingController: providerRead.nameController,
              focusNode: _nameFocusNode,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Client>.empty();
                }
                // Use local synchronous search for instant results
                return providerWatch.searchClientsLocal(textEditingValue.text);
              },
              onSelected: (Client client) {
                providerRead.fillClientData(client);
                _nameFocusNode.unfocus();
              },
              displayStringForOption: (Client client) => client.fullName,
              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                      onSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
              optionsViewBuilder:
                  (
                    BuildContext context,
                    AutocompleteOnSelected<Client> onSelected,
                    Iterable<Client> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        color: Colors.white,
                        child: Container(
                          width:
                              MediaQuery.of(context).size.width -
                              80, // Approx width relative to screen padding
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Client option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option.fullName,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  option.phone,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: providerRead.phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  if (providerRead.nameController.text.isNotEmpty) {
                    _nextStep();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El nombre es obligatorio')),
                    );
                  }
                },
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
      _buildStep(
        index: 1,
        title: 'Datos del Vehículo',
        isActive: _currentStep == 1,
        isCompleted: _currentStep > 1,
        summary: providerWatch.selectedVehicleType.toUpperCase().replaceAll(
          '_',
          ' ',
        ),
        content: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: providerRead.vehicleTypesList.length,
              itemBuilder: (context, index) {
                final type = providerWatch.vehicleTypesList[index];
                final isSelected = providerWatch.selectedVehicleType == type;
                return _VehicleTypeCard(
                  title: type.toUpperCase().replaceAll('_', ' '),
                  icon: _getVehicleIcon(type),
                  isSelected: isSelected,
                  onTap: () {
                    providerRead.setVehicleType(type);
                    // Optional: Auto advance? No, user might want to check custom type
                  },
                );
              },
            ),
            if (providerWatch.selectedVehicleType == 'otro') ...[
              const SizedBox(height: 16),
              TextField(
                controller: providerRead.customTypeController,
                decoration: const InputDecoration(
                  labelText: 'Especifique el Tipo *',
                  hintText: 'Ej. Triciclo',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _prevStep, child: const Text('Atrás')),
                ElevatedButton(
                  onPressed: () {
                    if (providerRead.selectedVehicleType == 'otro' &&
                        providerRead.customTypeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Especifique el tipo de vehículo'),
                        ),
                      );
                      return;
                    }
                    _nextStep();
                  },
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
      _buildStep(
        index: 2,
        title: 'Servicios',
        isActive: _currentStep == 2,
        isCompleted: _currentStep > 2,
        summary: providerWatch.getServiceSummary(isEmployee: isEmployee),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lavado Base (Requerido)',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...providerWatch.washTypes.where((w) => w.category == 'base').map((
              service,
            ) {
              final price = service.getPriceFor(
                providerWatch.selectedVehicleType,
              );
              final isSelected =
                  providerWatch.selectedBaseServiceId == service.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.05)
                      : Colors.white,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Radio<String>(
                    value: service.id,
                    // ignore: deprecated_member_use
                    groupValue: providerWatch.selectedBaseServiceId,
                    // ignore: deprecated_member_use
                    onChanged: (value) => providerRead.setBaseService(value!),
                    activeColor: theme.primaryColor,
                  ),
                  title: Text(
                    service.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                  ),
                  subtitle: isEmployee
                      ? null
                      : Text(
                          'L. ${price.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(),
                        ),
                  onTap: () => providerRead.setBaseService(service.id),
                ),
              );
            }),

            const SizedBox(height: 24),
            Text(
              'Extras (Opcional)',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...providerWatch.washTypes.where((w) => w.category == 'extra').map((
              service,
            ) {
              final price = service.getPriceFor(
                providerWatch.selectedVehicleType,
              );
              final isSelected = providerWatch.selectedExtrasIds.contains(
                service.id,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.05)
                      : Colors.white,
                ),
                child: CheckboxListTile(
                  title: Text(
                    service.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                  ),
                  subtitle: isEmployee
                      ? null
                      : Text(
                          'L. ${price.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(),
                        ),
                  value: isSelected,
                  onChanged: (_) => providerRead.toggleExtra(service.id),
                  activeColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _prevStep, child: const Text('Atrás')),
                ElevatedButton(
                  onPressed: () {
                    if (providerRead.selectedBaseServiceId != null) {
                      _nextStep();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seleccione un lavado base'),
                        ),
                      );
                    }
                  },
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
      _buildStep(
        index: 3,
        title: 'Fotos y Confirmación',
        isActive: _currentStep == 3,
        isCompleted: false, // Last step
        content: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount:
                  providerWatch.existingPhotoUrls.length +
                  providerWatch.selectedImages.length +
                  1,
              itemBuilder: (context, index) {
                // 1. Add Button (Last Item)
                if (index ==
                    providerWatch.existingPhotoUrls.length +
                        providerWatch.selectedImages.length) {
                  return GestureDetector(
                    onTap: providerRead.pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey.shade600),
                          const SizedBox(height: 4),
                          Text(
                            'Agregar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 2. Existing Images (First Group)
                if (index < providerWatch.existingPhotoUrls.length) {
                  final url = providerWatch.existingPhotoUrls[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => providerRead.removeExistingImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red, // Distinct color for existing?
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
                }

                // 3. New Images (Second Group)
                final newIndex = index - providerWatch.existingPhotoUrls.length;
                final image = providerWatch.selectedImages[newIndex];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(image, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => providerRead.removeImage(newIndex),
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
            const SizedBox(height: 32),

            if (!isEmployee)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Subtotal',
                      value: 'L. ${providerWatch.subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'ISV (15%)',
                      value: 'L. ${providerWatch.isv.toStringAsFixed(2)}',
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'TOTAL',
                      value: 'L. ${providerWatch.total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: providerWatch.isLoading
                    ? null
                    : () async {
                        final auth = context.read<AuthProvider>();
                        if (auth.currentUser?.companyId == null) return;

                        final success = await providerRead.submitEntry(
                          auth.currentUser!.companyId,
                          branchId: auth.currentUser!.branchId,
                          userId: auth.currentUser?.id,
                          userEmail: auth.currentUser?.email,
                          existingVehicle: widget.vehicle,
                        );
                        if (success && context.mounted) {
                          providerRead.clearForm();
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
                  backgroundColor: const Color(0xFF4ADE80), // Green
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: providerWatch.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        (widget.vehicle != null)
                            ? 'Guardar Cambios'
                            : 'Finalizar Ingreso',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _prevStep,
                child: const Text('Atrás'),
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ingreso de Vehículo',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: steps.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
        itemBuilder: (ctx, i) => steps[i],
      ),
    );
  }

  Widget _buildStep({
    required int index,
    required String title,
    required bool isActive,
    required bool isCompleted,
    required Widget content,
    String? summary,
  }) {
    // Custom Expansion-like Panel
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF1E88E5) : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              // Allow jumping back to completed steps
              if (index < _currentStep) {
                setState(() => _currentStep = index);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1E88E5)
                          : (isCompleted ? Colors.green : Colors.grey.shade200),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isActive
                                ? const Color(0xFF1E88E5)
                                : Colors.black87,
                          ),
                        ),
                        if (!isActive && summary != null)
                          Text(
                            summary,
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCompleted && !isActive)
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Content (Animated Size could be used here but keeping simple)
          if (isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTypeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? const Color(0xFF1E88E5)
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF1E88E5),
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
