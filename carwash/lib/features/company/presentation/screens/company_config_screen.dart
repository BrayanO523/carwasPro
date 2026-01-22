import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/billing/domain/entities/fiscal_config.dart';
import 'package:carwash/features/billing/presentation/providers/billing_provider.dart';
import 'package:carwash/features/company/domain/repositories/company_repository.dart';
import 'package:carwash/features/branch/domain/entities/branch.dart';
import 'package:carwash/features/branch/domain/repositories/branch_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CompanyConfigScreen extends StatefulWidget {
  const CompanyConfigScreen({super.key});

  @override
  State<CompanyConfigScreen> createState() => _CompanyConfigScreenState();
}

class _CompanyConfigScreenState extends State<CompanyConfigScreen> {
  // Fiscal Controllers
  late TextEditingController _caiController;
  late TextEditingController _companyRtnController;
  late TextEditingController _rangeMinController;
  late TextEditingController _rangeMaxController;
  late TextEditingController _deadlineController;
  late TextEditingController _companyEmailController;
  late TextEditingController _companyPhoneController;
  late TextEditingController _branchAddressController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _companyId;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    _caiController = TextEditingController();
    _companyRtnController = TextEditingController();
    _rangeMinController = TextEditingController();
    _rangeMaxController = TextEditingController();
    _deadlineController = TextEditingController();
    _companyEmailController = TextEditingController();
    _companyPhoneController = TextEditingController();
    _branchAddressController = TextEditingController();

    _loadData();
  }

  @override
  void dispose() {
    _caiController.dispose();
    _companyRtnController.dispose();
    _rangeMinController.dispose();
    _rangeMaxController.dispose();
    _deadlineController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _branchAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final companyRepo = context.read<CompanyRepository>();
    final branchRepo = context.read<BranchRepository>();

    try {
      final user = authProvider.currentUser;
      if (user == null) return;

      _companyId = user.companyId;
      final company = await companyRepo.getCompany(_companyId!);

      // Attempt to find branch
      Branch? branch;
      final branchId = user.branchId;
      if (branchId != null && branchId.isNotEmpty) {
        branch = await branchRepo.getBranch(branchId);
        _branchId = branchId;
      } else {
        final branches = await branchRepo.getBranches(_companyId!);
        if (branches.isNotEmpty) {
          branch = branches.first;
          _branchId = branch.id;
        }
      }

      // Load Fiscal Config
      await context.read<BillingProvider>().loadFiscalConfig(
        _companyId!,
        _branchId,
      );

      if (mounted) {
        final fiscalConfig = context.read<BillingProvider>().fiscalConfig;

        // Defaults if no config
        if (fiscalConfig != null) {
          _caiController.text = fiscalConfig.cai;
          _companyRtnController.text = fiscalConfig.rtn;
          _rangeMinController.text = fiscalConfig.rangeMin;
          _rangeMaxController.text = fiscalConfig.rangeMax;
          _deadlineController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(fiscalConfig.deadline);
          _companyEmailController.text = fiscalConfig.email;
          _companyPhoneController.text = fiscalConfig.phone;
          _branchAddressController.text = fiscalConfig.address;
        } else {
          // Preset from Company/Branch if new
          if (company != null) {
            _companyRtnController.text = company.rtn;
            _companyEmailController.text = company.email;
            _companyPhoneController.text = branch?.phone ?? company.phone;
            _branchAddressController.text = branch?.address ?? company.address;
          }
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('Error loading company config: $e');
    }
  }

  Future<void> _saveConfig() async {
    if (_companyId == null) return;

    setState(() => _isSaving = true);
    try {
      final existingConfig = context.read<BillingProvider>().fiscalConfig;

      // Parse Date
      DateTime deadline;
      try {
        deadline = DateFormat('dd/MM/yyyy').parse(_deadlineController.text);
      } catch (_) {
        deadline = DateTime.now().add(const Duration(days: 365));
      }

      final newConfig = FiscalConfig(
        id: existingConfig?.id ?? '',
        companyId: _companyId!,
        branchId: _branchId,
        cai: _caiController.text,
        rtn: _companyRtnController.text,
        rangeMin: _rangeMinController.text,
        rangeMax: _rangeMaxController.text,
        currentSequence:
            existingConfig?.currentSequence ?? _rangeMinController.text,
        deadline: deadline,
        email: _companyEmailController.text,
        phone: _companyPhoneController.text,
        address: _branchAddressController.text,
      );

      await context.read<BillingProvider>().updateFiscalConfig(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada correctamente')),
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
      appBar: AppBar(title: const Text('Configuración Fiscal (Empresa)')),
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
                          'RTN Empresa',
                          isNumber: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _caiController,
                          'CAI (Clave de Autorización)',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _rangeMinController,
                                'Rango Inicial',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                _rangeMaxController,
                                'Rango Final',
                              ),
                            ),
                          ],
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
                    title: 'Datos de Contacto',
                    icon: Icons.contact_phone,
                    child: Column(
                      children: [
                        _buildTextField(
                          _companyEmailController,
                          'Email Facturación',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(_companyPhoneController, 'Teléfono'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          _branchAddressController,
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
