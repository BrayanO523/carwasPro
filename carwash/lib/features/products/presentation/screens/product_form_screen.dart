import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/branch/presentation/providers/branch_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  bool _isActive = true;
  String _selectedCategory = 'Aceites';
  List<String> _selectedBranchIds = [];

  final List<String> _categories = [
    'Aceites',
    'Refrigerantes',
    'Aromatizantes',
    'Lubricantes',
    'Filtros',
    'Bebidas',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p?.price.toStringAsFixed(2) ?? '',
    );
    if (p != null && _categories.contains(p.category)) {
      _selectedCategory = p.category;
    }
    _isActive = p?.isActive ?? true;
    _selectedBranchIds = List.from(p?.branchIds ?? []);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final companyId = authProvider.currentUser?.companyId;
      if (companyId != null) {
        final branchProvider = context.read<BranchProvider>();
        await branchProvider.loadBranches(companyId);

        // Auto-select all if new or currently empty
        if (mounted && _selectedBranchIds.isEmpty && widget.product == null) {
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
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBranchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos una sucursal')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final companyId = authProvider.currentUser?.companyId;

    if (companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario sin empresa')),
      );
      return;
    }

    final newProduct = Product(
      id: widget.product?.id ?? '',
      companyId: companyId,
      branchIds: _selectedBranchIds,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      category: _selectedCategory,
      isActive: _isActive,
      imageUrl: widget.product?.imageUrl,
    );

    try {
      await context.read<ProductProvider>().saveProduct(newProduct);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.product != null) {
      try {
        if (!mounted) return;
        await context.read<ProductProvider>().deleteProduct(widget.product!.id);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  Widget _buildBranchSelector() {
    final branches = context.watch<BranchProvider>().branches;
    final areAllSelected =
        branches.isNotEmpty && _selectedBranchIds.length == branches.length;

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text(
              'Seleccionar Todas las Sucursales',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: areAllSelected,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedBranchIds = branches.map((b) => b.id).toList();
                } else {
                  _selectedBranchIds.clear();
                }
              });
            },
          ),
          const Divider(height: 1),
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
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Producto' : 'Nuevo Producto',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Switch
              SwitchListTile(
                title: const Text(
                  'Producto Activo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Disponible para la venta'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción Corta',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (L.)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (double.tryParse(val) == null) return 'Inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: 24),

              // Branch Selection
              const Text(
                'Disponibilidad por Sucursal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildBranchSelector(),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
