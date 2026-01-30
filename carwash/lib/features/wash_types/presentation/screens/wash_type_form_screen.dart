import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/wash_type.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart'; // Corrected Import
import '../providers/wash_type_provider.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/branch/presentation/providers/branch_provider.dart';

class WashTypeFormScreen extends StatefulWidget {
  final WashType? washType; // If null, creating new

  const WashTypeFormScreen({super.key, this.washType});

  @override
  State<WashTypeFormScreen> createState() => _WashTypeFormScreenState();
}

class _WashTypeFormScreenState extends State<WashTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;

  // Price Controllers
  final Map<String, TextEditingController> _priceControllers = {};

  String _category = 'base';
  bool _isActive = true;

  // Branch State
  List<String> _selectedBranchIds = [];
  // bool _needsInitialBranchSelection = true; // Logic handled in postFrameCallback via empty check

  @override
  void initState() {
    super.initState();
    final item = widget.washType;

    _nameController = TextEditingController(text: item?.name ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _category = item?.category ?? 'base';
    _isActive = item?.isActive ?? true;
    _selectedBranchIds = List.from(item?.branchIds ?? []);

    // Initialize one controller per vehicle type
    for (var type in Vehicle.types) {
      final price = item?.prices[type] ?? 0;
      _priceControllers[type] = TextEditingController(
        text: price > 0 ? price.toStringAsFixed(0) : '',
      );
    }

    // Load branches if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        final branchProvider = context.read<BranchProvider>();
        await branchProvider.loadBranches(user.companyId);

        // Post-load logic: If we are editing (or new) and the list is empty,
        // it historically meant "ALL". Now we want EXPLICIT ALL.
        // So we populate the list with all loaded branch IDs.
        // Exception: If we really meant "none", but for WashTypes that's rare/invalid as active service.
        if (mounted && _selectedBranchIds.isEmpty) {
          setState(() {
            _selectedBranchIds = branchProvider.branches
                .map((b) => b.id)
                .toList();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prices = <String, double>{};
    for (var entry in _priceControllers.entries) {
      final val = double.tryParse(entry.value.text) ?? 0;
      if (val > 0) {
        prices[entry.key] = val;
      }
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final success = await context.read<WashTypeProvider>().saveWashType(
      id: widget.washType?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      isActive: _isActive,
      prices: prices,
      companyId: user.companyId,
      branchIds: _selectedBranchIds,
      isGlobal: widget.washType?.companyId == null && widget.washType != null,
    );

    if (success && mounted) {
      context.pop();
    }
  }

  Widget _buildBranchSelector() {
    final branches = context.read<BranchProvider>().branches;
    final areAllSelected =
        branches.isNotEmpty && _selectedBranchIds.length == branches.length;

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Select All Checkbox
          CheckboxListTile(
            title: const Text('Seleccionar Todas las Sucursales'),
            value: areAllSelected,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedBranchIds = branches.map((b) => b.id).toList();
                } else {
                  _selectedBranchIds.clear(); // Deselect All
                }
              });
            },
          ),
          const Divider(height: 1),

          if (branches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Cargando sucursales o no existen datos...'),
            ),

          // Expandable list or just list? The expansion tile was useful for space.
          // Let's keep it expanded or inside an ExpansionTile but with the Checkbox as the "header"?
          // Use requests "change switch... to checkbox".
          // I will use an ExpansionTile where the TITLE is the "Select All" logic? No, that's messy interacting with expansion.
          // I'll put the "Select All" outside, and then the list.
          // Or just a normal list. There might be 100 branches (user said).
          // So a scrollable list inside a constrained height or just let it expand?
          // Using ExpansionTile for the list part might be good.
          ExpansionTile(
            title: Text(
              '${_selectedBranchIds.length} sucursales seleccionadas',
            ),
            initiallyExpanded: true,
            children: branches.map((branch) {
              final isSelected = _selectedBranchIds.contains(branch.id);
              return CheckboxListTile(
                title: Text(branch.name),
                value: isSelected,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedBranchIds.add(branch.id);
                    } else {
                      _selectedBranchIds.remove(branch.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.washType != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Servicio' : 'Nuevo Servicio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Switch
            SwitchListTile(
              title: const Text('Activo'),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
            ),
            const Divider(),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Servicio',
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: const [
                DropdownMenuItem(
                  value: 'base',
                  child: Text('Servicio Base (Lavado)'),
                ),
                DropdownMenuItem(value: 'extra', child: Text('Servicio Extra')),
              ],
              onChanged: (val) {
                setState(() {
                  _category = val!;
                  if (_category == 'base') {
                    _selectedBranchIds.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 24),

            // Branch Selection
            if (_category == 'extra') ...[
              _buildBranchSelector(),
              const SizedBox(height: 24),
            ],

            const Text(
              'Precios por Tipo de Vehículo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Dynamic Price Fields Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: Vehicle.types.length,
              itemBuilder: (context, index) {
                final type = Vehicle.types[index];
                final label =
                    type[0].toUpperCase() +
                    type.substring(1).replaceAll('_', ' ');
                final icon = _getIconForType(type);

                return _PriceField(
                  controller: _priceControllers[type]!,
                  label: label,
                  icon: icon,
                );
              },
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type.contains('moto')) return Icons.two_wheeler;
    if (type.contains('trimoto')) return Icons.electric_rickshaw;
    if (type.contains('turismo')) return Icons.directions_car;
    if (type.contains('pick_up')) {
      return Icons.directions_car_filled; // Changed to car filled
    }
    if (type.contains('camioneta') || type.contains('microbus')) {
      return Icons.airport_shuttle;
    }
    if (type.contains('camion') ||
        type.contains('cabezal') ||
        type.contains('autobus')) {
      return Icons.local_shipping;
    }
    return Icons.directions_car_filled; // Default
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _PriceField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        prefixText: 'L. ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
