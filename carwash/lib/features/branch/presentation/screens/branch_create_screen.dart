import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickalert/quickalert.dart';
import '../../../billing/domain/entities/fiscal_config.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../providers/branch_provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import 'branch_fiscal_config_screen.dart';

class BranchCreateScreen extends StatefulWidget {
  const BranchCreateScreen({super.key});

  @override
  State<BranchCreateScreen> createState() => _BranchCreateScreenState();
}

class _BranchCreateScreenState extends State<BranchCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _establishmentController = TextEditingController(
    text: '000',
  ); // Default
  bool _willInvoice = true; // Default to Fiscal
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateEstablishmentNumber();
  }

  void _calculateEstablishmentNumber() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branches = context.read<BranchProvider>().branches;
      int maxEst = -1;

      for (var b in branches) {
        final est = int.tryParse(b.establishmentNumber) ?? 0;
        if (est > maxEst) maxEst = est;
      }

      String defaultEst = '000';
      if (maxEst >= 0) {
        defaultEst = (maxEst + 1).toString().padLeft(3, '0');
      }

      setState(() {
        _establishmentController.text = defaultEst;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _establishmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = context.read<AuthProvider>().currentUser?.companyId;
    if (companyId == null) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<BranchProvider>();
      final newBranch = await provider.addBranch(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        companyId: companyId,
        establishmentNumber: _establishmentController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (newBranch != null) {
          if (_willInvoice) {
            // Fiscal Mode: Show Alert and Navigate to Config
            QuickAlert.show(
              context: context,
              type: QuickAlertType.info,
              title: 'Información',
              text: 'Debe completar la información del SAR de esta sucursal',
              confirmBtnText: 'Entendido',
              confirmBtnColor: const Color(0xFFFBBF24),
              onConfirmBtnTap: () {
                context.pop(); // Close Alert
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BranchFiscalConfigScreen(
                      companyId: companyId,
                      branch: newBranch,
                    ),
                  ),
                );
              },
            );
          } else {
            // Non-Fiscal Mode: Create Empty Config and Close
            try {
              // Create empty/non-fiscal config
              final config = FiscalConfig(
                id: '', // New
                companyId: companyId,
                branchId: newBranch.id,
                cai: null, // NULL
                rtn: null, // NULL
                establishment: null, // NULL
                emissionPoint: null, // NULL
                documentType: null, // NULL
                rangeMin: null,
                rangeMax: null,
                currentSequence: 1, // Start internal sequence at 1
                authorizationDate: null,
                deadline: null,
                email: '',
                phone: newBranch.phone,
                address: newBranch.address,
                active: true,
              );

              await context.read<BillingProvider>().updateFiscalConfig(config);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sucursal creada (Modo Recibo/Ticket)'),
                  ),
                );
                context.pop(); // Return to list
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creando config: $e')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      appBar: AppBar(
        title: Text(
          'Nueva Sucursal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información General',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Form Fields in a Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Sucursal',
                        prefixIcon: Icon(Icons.store_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección Completa',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fiscal Checkbox
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '¿Esta sucursal facturará?',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Si se desactiva, solo generará recibos internos.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      value: _willInvoice,
                      activeTrackColor: const Color(0xFF1E88E5),
                      onChanged: (val) {
                        setState(() => _willInvoice = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_willInvoice)
                      TextFormField(
                        controller: _establishmentController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Nº Establecimiento (Automático)',
                          prefixIcon: const Icon(Icons.numbers),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: const OutlineInputBorder(),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFF1E88E5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _willInvoice
                              ? 'Crear y Configurar'
                              : 'Crear Sucursal',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
