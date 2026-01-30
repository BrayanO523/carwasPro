import 'dart:developer';

import 'package:carwash/features/billing/domain/entities/fiscal_config.dart';
import 'package:carwash/features/billing/presentation/providers/billing_provider.dart';
import 'package:carwash/features/branch/domain/entities/branch.dart';
import 'package:carwash/features/company/domain/repositories/company_repository.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/branch/presentation/providers/branch_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:carwash/features/billing/presentation/screens/cai_history_screen.dart';

class BranchFiscalConfigScreen extends StatefulWidget {
  final String companyId;
  final Branch branch;

  const BranchFiscalConfigScreen({
    super.key,
    required this.companyId,
    required this.branch,
  });

  @override
  State<BranchFiscalConfigScreen> createState() =>
      _BranchFiscalConfigScreenState();
}

class _BranchFiscalConfigScreenState extends State<BranchFiscalConfigScreen> {
  // Fiscal Controllers
  late TextEditingController _caiController;
  late TextEditingController _companyRtnController;
  late TextEditingController _establishmentController; // 000
  late TextEditingController _emissionPointController; // 001
  late TextEditingController _docTypeController; // 01
  late TextEditingController _rangeMinController;
  late TextEditingController _rangeMaxController;
  late TextEditingController _authorizationDateController;
  late TextEditingController _deadlineController;
  late TextEditingController _emailController;
  late TextEditingController _nameController; // Branch Name
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _caiController = TextEditingController();
    _companyRtnController = TextEditingController();
    _establishmentController = TextEditingController();
    _emissionPointController = TextEditingController(text: '001');
    _docTypeController = TextEditingController(text: '01');
    _rangeMinController = TextEditingController();
    _rangeMaxController = TextEditingController();
    _authorizationDateController = TextEditingController();
    _deadlineController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    // Branch Fields
    _nameController = TextEditingController(text: widget.branch.name);
    _phoneController.text = widget.branch.phone; // Pre-fill
    _addressController.text = widget.branch.address; // Pre-fill

    _loadData();
  }

  @override
  void dispose() {
    _caiController.dispose();
    _companyRtnController.dispose();
    _establishmentController.dispose();
    _emissionPointController.dispose();
    _docTypeController.dispose();
    _rangeMinController.dispose();
    _rangeMaxController.dispose();
    _authorizationDateController.dispose();
    _deadlineController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = context.read<AuthProvider>().currentUser;
      final emissionPoint = user?.emissionPoint;

      // Load Fiscal Config for SPECIFIC Branch AND Emission Point
      await context.read<BillingProvider>().loadFiscalConfig(
        widget.companyId,
        widget.branch.id,
        emissionPoint: emissionPoint,
      );

      if (mounted) {
        final fiscalConfig = context.read<BillingProvider>().fiscalConfig;

        if (fiscalConfig != null) {
          _caiController.text = fiscalConfig.cai ?? '';
          // _companyRtnController.text = fiscalConfig.rtn; // Handled below
          _establishmentController.text = fiscalConfig.establishment ?? '';
          _emissionPointController.text =
              emissionPoint ??
              fiscalConfig.emissionPoint ??
              '001'; // Prefer User's point logic
          _docTypeController.text = fiscalConfig.documentType ?? '01';
          _rangeMinController.text = (fiscalConfig.rangeMin ?? '').toString();
          _rangeMaxController.text = (fiscalConfig.rangeMax ?? '').toString();

          if (fiscalConfig.authorizationDate != null) {
            _authorizationDateController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(fiscalConfig.authorizationDate!);
          }

          if (fiscalConfig.deadline != null) {
            _deadlineController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(fiscalConfig.deadline!);
          }

          _emailController.text = fiscalConfig.email;
          _phoneController.text = fiscalConfig.phone;
          _addressController.text = fiscalConfig.address;
        } else {
          // Pre-fill defaults from Branch & User
          _establishmentController.text = widget.branch.establishmentNumber;
          _emissionPointController.text = emissionPoint ?? '001';
          _phoneController.text = widget.branch.phone;
          _addressController.text = widget.branch.address;
        }

        // ALWAYS fetch Company to get the Master RTN
        try {
          final company = await context.read<CompanyRepository>().getCompany(
            widget.companyId,
          );
          if (company != null) {
            _companyRtnController.text = company.rtn;
          }
        } catch (e) {
          log("Error loading company RTN: $e");
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      log('Error loading branch fiscal config: $e');
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final existingConfig = context.read<BillingProvider>().fiscalConfig;

      // Parse Dates
      DateTime deadline;
      DateTime authorizationDate;
      try {
        deadline = DateFormat('dd/MM/yyyy').parse(_deadlineController.text);
        authorizationDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(_authorizationDateController.text);
      } catch (_) {
        throw Exception("Fecha inválida");
      }

      // Parse Ranges
      final rangeMin = int.tryParse(_rangeMinController.text) ?? 1;
      final rangeMax = int.tryParse(_rangeMaxController.text) ?? 1;

      // Determine Sequence
      int currentSeq = existingConfig?.currentSequence ?? rangeMin;

      // Validate Establishment matches Branch?
      // Strict: forcing establishment to match branch's configured number
      // But user might want to edit it here if it changed.
      // Let's take the controller value.

      final newConfig = FiscalConfig(
        id: existingConfig?.id ?? '',
        companyId: widget.companyId,
        branchId: widget.branch.id, // STRICTLY BRANCH SCOPED
        cai: _caiController.text,
        rtn: _companyRtnController.text,
        establishment: _establishmentController.text.padLeft(3, '0'),
        emissionPoint: _emissionPointController.text.padLeft(3, '0'),
        documentType: _docTypeController.text.padLeft(2, '0'),
        rangeMin: rangeMin,
        rangeMax: rangeMax,
        currentSequence: currentSeq,
        authorizationDate: authorizationDate,
        deadline: deadline,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
      );

      // 1. Update Branch Details
      if (!mounted) return;
      await context.read<BranchProvider>().updateBranch(
        id: widget.branch.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        companyId: widget.companyId,
        establishmentNumber: _establishmentController.text.trim(),
      );

      // 2. Update Fiscal Config
      if (!mounted) return;
      await context.read<BillingProvider>().updateFiscalConfig(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración Fiscal de Sucursal guardada'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Config. Fiscal - ${widget.branch.name}'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Open History
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CaiHistoryScreen(
                    companyId: widget.companyId,
                    branchId: widget.branch.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('Historial'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(
                    title: 'Datos Fiscales (SAR)',
                    icon: Icons.receipt_long,
                    child: Column(
                      children: [
                        _buildTextField(
                          _companyRtnController,
                          'RTN Empresa (Global)',
                          isNumber: true,
                          readOnly: true, // RTN is company-wide
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _caiController,
                          'CAI (Clave de Autorización)',
                        ),
                        const SizedBox(height: 12),
                        // SAR Format Fields (Vertical)
                        _buildTextField(
                          _establishmentController,
                          'Establecimiento (Ej: 001)',
                          isNumber: true,
                          readOnly: true, // Locked to Branch Entity
                        ),
                        const SizedBox(height: 12),
                        // Punto de Emision is locked to the current User's assigned point (the "Cashier").
                        _buildTextField(
                          _emissionPointController,
                          'Punto de Emisión (Usuario)',
                          isNumber: true,
                          readOnly: true, // Locked to User
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _docTypeController,
                          'Tipo de Documento (Ej: 01)',
                          isNumber: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _rangeMinController,
                                'Rango Inicial',
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                _rangeMaxController,
                                'Rango Final',
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _authorizationDateController,
                          'Fecha Autorización (dd/MM/yyyy)',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _deadlineController,
                          'Fecha Límite Emisión (dd/MM/yyyy)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Datos de Contacto (Branch)',
                    icon: Icons.contact_phone,
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Nombre de Sucursal'),
                        const SizedBox(height: 12),
                        _buildTextField(_emailController, 'Email Facturación'),
                        const SizedBox(height: 12),
                        _buildTextField(_phoneController, 'Teléfono'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _addressController,
                          'Dirección Establecimiento',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveConfig,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving ? 'GUARDANDO...' : 'GUARDAR CONFIGURACIÓN',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        fillColor: readOnly ? Colors.grey[200] : null,
        filled: readOnly,
      ),
    );
  }
}
