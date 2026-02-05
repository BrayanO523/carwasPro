import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/vehicle_entry_repository.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/credit_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_permissions.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _rtnController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  // Credit Info
  bool _creditEnabled = false;
  late TextEditingController _creditLimitController;
  late TextEditingController _creditDaysController;
  late TextEditingController _creditNotesController;

  bool _isLoading = false;
  bool _canManageCredit = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameController = TextEditingController(text: c?.fullName ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _rtnController = TextEditingController(text: c?.rtn ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');

    _creditEnabled = c?.creditEnabled ?? false;
    _creditLimitController = TextEditingController(
      text: c?.creditLimit.toString() ?? '0',
    );
    _creditDaysController = TextEditingController(
      text: c?.creditDays.toString() ?? '30',
    );
    _creditNotesController = TextEditingController(text: c?.creditNotes ?? '');

    // Permission checks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final isNew = widget.client == null;
      final requiredPermission = isNew
          ? AppPermissions.createClient
          : AppPermissions.editClient;

      if (!auth.hasPermission(requiredPermission)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permiso para esta acción'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        return;
      }

      setState(() {
        _canManageCredit = auth.hasPermission(
          AppPermissions.manageClientCredit,
        );
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) throw Exception('No user');

      final repo = context.read<VehicleEntryRepository>();

      final isNew = widget.client == null;
      final now = DateTime.now();

      final client = Client(
        id: widget.client?.id ?? const Uuid().v4(),
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        rtn: _rtnController.text.trim().isEmpty
            ? null
            : _rtnController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        companyId: user.companyId,
        branchId:
            widget.client?.branchId ??
            user.branchId, // Preserve or assign from user
        // Audit fields
        createdBy: isNew ? user.id : widget.client?.createdBy,
        createdAt: isNew ? now : widget.client?.createdAt,
        updatedBy: user.id,
        updatedAt: now,
        creditProfile: CreditProfile(
          active: _creditEnabled,
          limit: double.tryParse(_creditLimitController.text) ?? 0.0,
          days: int.tryParse(_creditDaysController.text) ?? 30,
          notes: _creditNotesController.text.trim().isEmpty
              ? null
              : _creditNotesController.text.trim(),
          currentBalance:
              widget.client?.currentBalance ?? 0.0, // Preserve balance
        ),
      );

      await repo.saveClient(client);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente guardado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.client == null ? 'Nuevo Cliente' : 'Editar Cliente',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información Personal'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rtnController,
                      decoration: const InputDecoration(
                        labelText: 'RTN (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Credit Section - Only visible with permission
              if (_canManageCredit) ...[
                _buildSectionTitle('Gestión de Crédito'),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: Text(
                    'Habilitar Crédito',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  value: _creditEnabled,
                  onChanged: (val) => setState(() => _creditEnabled = val),
                  subtitle: const Text(
                    'Permite facturar a crédito a este cliente',
                  ),
                ),
              ],

              if (_canManageCredit && _creditEnabled) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _creditLimitController,
                        decoration: const InputDecoration(
                          labelText: 'Límite (L)',
                          border: OutlineInputBorder(),
                          prefixText: 'L. ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          final val = double.tryParse(v);
                          if (val == null || val < 0) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _creditDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Días Plazo',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          final val = int.tryParse(v);
                          if (val == null || val < 1) return 'Mín 1 día';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _creditNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas de Crédito',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
