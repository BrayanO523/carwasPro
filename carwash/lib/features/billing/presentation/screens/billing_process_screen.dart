import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:carwash/features/entry/domain/entities/vehicle.dart';
import 'package:carwash/features/entry/domain/entities/client.dart';
import 'package:carwash/features/entry/domain/repositories/vehicle_entry_repository.dart';
import 'package:carwash/features/auth/presentation/providers/auth_provider.dart';
import 'package:carwash/features/billing/presentation/providers/billing_provider.dart';
import 'package:carwash/features/branch/domain/repositories/branch_repository.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed: Moved to Provider
import 'package:carwash/features/company/domain/entities/company.dart';
import 'package:carwash/features/company/domain/repositories/company_repository.dart';
import 'package:carwash/core/utils/pdf_service.dart';
import 'package:carwash/core/utils/number_to_words.dart';
import 'package:go_router/go_router.dart';

import 'package:carwash/features/branch/domain/entities/branch.dart';
import 'package:carwash/features/billing/domain/entities/invoice_item.dart';

class BillingProcessScreen extends StatefulWidget {
  final Vehicle vehicle;

  const BillingProcessScreen({super.key, required this.vehicle});

  @override
  State<BillingProcessScreen> createState() => _BillingProcessScreenState();
}

class _BillingProcessScreenState extends State<BillingProcessScreen> {
  // Controllers for Client Info
  late TextEditingController _rtnController;
  late TextEditingController _emailController;
  late TextEditingController _clientAddressController;

  // Controllers for Fiscal Info

  List<InvoiceItem> _invoiceItems = [];
  bool _isLoadingItems = true;

  Client? _client;
  Branch? _branch;
  Company? _company;
  bool _isLoadingClient = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Client Controllers
    _rtnController = TextEditingController();
    _emailController = TextEditingController();
    _clientAddressController = TextEditingController();

    // Fiscal Controllers

    _loadData(); // Load Client, Branch, and Fiscal Config
    _loadInvoiceItems();
  }

  Future<void> _loadInvoiceItems() async {
    final billingProvider = context.read<BillingProvider>();

    // Ensure catalog is loaded (cached)
    // Ensure catalog is loaded (cached) - passing filters
    await billingProvider.loadWashTypesCatalog(
      widget.vehicle.companyId,
      branchId: widget.vehicle.branchId,
    );

    if (widget.vehicle.services.isEmpty) {
      if (mounted) setState(() => _isLoadingItems = false);
      return;
    }

    final vehicleType = widget.vehicle.vehicleType ?? 'turismo';
    final List<InvoiceItem> items = [];

    for (final serviceId in widget.vehicle.services) {
      final priceData = billingProvider.getServicePrice(serviceId, vehicleType);

      // Only add if found (priceData not empty)
      if (priceData['price'] != null) {
        items.add(
          InvoiceItem(
            description: (priceData['name'] as String?) ?? 'Servicio',
            unitPrice: (priceData['price'] as double?) ?? 0.0,
            quantity: 1,
            taxType: '15',
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _invoiceItems = items;
        _isLoadingItems = false;
      });
    }
  }

  Future<void> _loadData() async {
    final vehicleRepo = context.read<VehicleEntryRepository>();
    final branchRepo = context.read<BranchRepository>();
    final companyRepo = context.read<CompanyRepository>();
    final authProvider = context.read<AuthProvider>();
    final billingProvider = context.read<BillingProvider>();

    try {
      // 1. Load Client
      final client = await vehicleRepo.getClientById(widget.vehicle.clientId);

      // 2. Load Branch & Company
      Branch? branch;
      Company? company;

      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        company = await companyRepo.getCompany(currentUser.companyId);

        final branchId = currentUser.branchId;
        if (branchId != null && branchId.isNotEmpty) {
          branch = await branchRepo.getBranch(branchId);
        } else {
          final branches = await branchRepo.getBranches(currentUser.companyId);
          if (branches.isNotEmpty) branch = branches.first;
        }

        // 3. Load Fiscal Config (Cached via Provider)
        if (company != null) {
          // This call is now optimized in the provider to be idempotent
          billingProvider.loadFiscalConfig(company.id, branch?.id);
        }
      }

      if (mounted) {
        setState(() {
          if (client != null) {
            _client = client;
            _rtnController.text = client.rtn ?? '';
            _clientAddressController.text = client.address ?? '';

            // Set Due Date from Credit Profile
            if (client.creditEnabled) {
              final days = client.creditProfile.days;
              _dueDate = DateTime.now().add(
                Duration(days: days > 0 ? days : 30),
              );
            }
          }
          _branch = branch;
          _company = company;
          _isLoadingClient = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClient = false);
      log('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _rtnController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _invoiceItems.fold(0, (sum, item) => sum + item.total);

  // Simplified calculation for now (assuming all is 15% and no discount)
  // In the full implementation, this will iterate items and check taxType
  double get _discountTotal => 0.0;
  double get _exemptAmount => 0.0;
  double get _taxableAmount15 => _subtotal;
  double get _taxableAmount18 => 0.0;

  double get _isv15 => _taxableAmount15 * 0.15;
  double get _isv18 => _taxableAmount18 * 0.18;

  double get _total => _subtotal - _discountTotal + _isv15 + _isv18;

  @override
  Widget build(BuildContext context) {
    // final companyName = context.watch<AuthProvider>().companyName ?? 'EMPRESA DEMO';
    // unused variable authProvider removed

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emitir Factura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuración de Facturación (Próximamente)'),
                ),
              );
            },
            tooltip: 'Configurar Datos de Facturación',
          ),
        ],
      ),
      body: _isLoadingClient || _isLoadingItems
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Title
                  Center(
                    child: Text(
                      'FACTURACIÓN / RECIBO',
                      style: GoogleFonts.notoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Invoice Metadata Card
                  _buildInvoiceMetaCard(),
                  const SizedBox(height: 16),

                  // 4. Client Card
                  _buildClientCard(),
                  const SizedBox(height: 16),

                  // 5. Service Detail Card
                  _buildServiceDetailCard(),
                  const SizedBox(height: 16),

                  // 6. Totals Card
                  _buildTotalsCard(),
                  const SizedBox(height: 16),

                  // 7. Payment Condition Card
                  _buildPaymentConditionCard(),
                  const SizedBox(height: 16),

                  // Action Button
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _processAndSave,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.print),
                    label: Text(
                      _isProcessing
                          ? 'PROCESANDO...'
                          : 'EMITIR ${_selectedDocType.toUpperCase()}',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      backgroundColor: _selectedDocType == 'invoice'
                          ? const Color(0xFF1E88E5)
                          : Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _selectedDocType = 'invoice'; // Default
  String _paymentCondition = 'contado';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  Widget _buildPaymentConditionCard() {
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
                const Icon(Icons.payment, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  'CONDICIÓN DE PAGO',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Contado'),
                    leading: Radio<String>(
                      value: 'contado',
                      // ignore: deprecated_member_use
                      groupValue: _paymentCondition,
                      // ignore: deprecated_member_use
                      onChanged: (val) =>
                          setState(() => _paymentCondition = val!),
                    ),
                    onTap: () => setState(() => _paymentCondition = 'contado'),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Crédito'),
                    leading: Radio<String>(
                      value: 'credito',
                      // ignore: deprecated_member_use
                      groupValue: _paymentCondition,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        setState(() => _paymentCondition = val!);
                        // Validar si cliente tiene crédito habilitado
                        if (_client != null && !_client!.creditEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Este cliente no tiene crédito habilitado',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                    onTap: () {
                      setState(() => _paymentCondition = 'credito');
                      if (_client != null && !_client!.creditEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Este cliente no tiene crédito habilitado',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_paymentCondition == 'credito') ...[
              const SizedBox(height: 12),
              if (_client != null && !_client!.creditEnabled)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este cliente no tiene crédito habilitado.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showEnableCreditDialog,
                          icon: const Icon(Icons.edit_note),
                          label: const Text('HABILITAR CRÉDITO AHORA'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _dueDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Vencimiento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                  ),
                ),
                const SizedBox(height: 8),
                if (_client != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance: L. ${_client!.currentBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Límite: L. ${_client!.creditLimit.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEnableCreditDialog() async {
    final limitController = TextEditingController();
    final daysController = TextEditingController(text: '30');
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Habilitar Crédito Rápido'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingrese los datos para habilitar el crédito a este cliente inmediatamente.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Límite de Crédito (L)',
                    border: OutlineInputBorder(),
                    prefixText: 'L. ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Días de Plazo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(context), // Cancel
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final limit = double.tryParse(limitController.text);
                        final days = int.tryParse(daysController.text);

                        if (limit == null || limit <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ingrese un límite válido'),
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final repo = context.read<VehicleEntryRepository>();
                          final updatedProfile = _client!.creditProfile
                              .copyWith(
                                active: true,
                                limit: limit,
                                days: days ?? 30,
                              );

                          final updatedClient = _client!.copyWith(
                            creditProfile: updatedProfile,
                          );

                          await repo.saveClient(updatedClient);

                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context); // Close dialog
                            this.setState(() {
                              _client = updatedClient;
                              _dueDate = DateTime.now().add(
                                Duration(days: days ?? 30),
                              );
                            });
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Crédito Habilitado!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => isLoading = false);
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al guardar'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar y Habilitar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller, // Editable
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildInvoiceMetaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Document Type Selector inside Card
            // Check if Fiscal Config allows Invoicing
            Builder(
              builder: (context) {
                final fiscalConfig = context
                    .watch<BillingProvider>()
                    .fiscalConfig;
                final canInvoice = (fiscalConfig?.cai?.isNotEmpty ?? false);

                // Force Receipt if cannot invoice
                if (!canInvoice && _selectedDocType == 'invoice') {
                  // Defer state update to next frame to avoid build error
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedDocType = 'receipt');
                  });
                }

                if (!canInvoice) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'MODO RECIBO: SUCURSAL SIN CAI',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'invoice',
                      label: Text('FACTURA'),
                      icon: Icon(Icons.description),
                    ),
                    ButtonSegment(
                      value: 'receipt',
                      label: Text('RECIBO'),
                      icon: Icon(Icons.receipt),
                    ),
                  ],
                  selected: {_selectedDocType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedDocType = newSelection.first;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Date and Number
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    ),
                    readOnly: true, // Picker logic later if needed
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Emisión',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Original / Copia Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Chip(
                  label: const Text('ORIGINAL: CLIENTE'),
                  backgroundColor: Colors.green[50],
                  labelStyle: TextStyle(
                    color: Colors.green[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: const Text('COPIA: EMISOR'),
                  backgroundColor: Colors.blue[50],
                  labelStyle: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard() {
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
                const Icon(Icons.person, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  'DATOS DEL CLIENTE',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Client Fields
            Text(
              'Cliente: ${widget.vehicle.clientName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_selectedDocType == 'invoice') ...[
              const SizedBox(height: 12),
              _buildTextField(_rtnController, 'RTN del Cliente'),
              const SizedBox(height: 12),
              _buildTextField(
                _clientAddressController,
                'Dirección del Consumidor',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailCard() {
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
                const Icon(Icons.list, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  'DETALLE DE SERVICIOS',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Table Header
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Descripción',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    'Cant.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 85,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(width: 60), // Actions placeholder
              ],
            ),
            const SizedBox(height: 8),
            // Items List
            ..._invoiceItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        item.quantity % 1 == 0
                            ? item.quantity.toInt().toString()
                            : item.quantity.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 85,
                      child: Text(
                        'L. ${item.total.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _showEditItemDialog(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _confirmRemoveItem(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Add Item Button
            TextButton.icon(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Subtotal Exento', _exemptAmount),
            _buildTotalRow('Subtotal Gravado 15%', _taxableAmount15),
            _buildTotalRow('Subtotal Gravado 18%', _taxableAmount18),
            _buildTotalRow('ISV 15%', _isv15),
            _buildTotalRow('ISV 18%', _isv18),
            const Divider(),
            _buildTotalRow('TOTAL A PAGAR', _total, isBold: true, fontSize: 18),
            const SizedBox(height: 8),
            Text(
              NumberToWords.convert(_total),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
  }) {
    if (amount == 0 && !isBold) {
      return const SizedBox.shrink(); // Hide 0 sections
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            'L. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveItem(int index) {
    final item = _invoiceItems[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de quitar "${item.description}" de la factura?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _invoiceItems.removeAt(index);
              });
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(int index) {
    final item = _invoiceItems[index];
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(
      text: item.unitPrice.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Precio Unitario (L.)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty =
                  double.tryParse(qtyController.text) ?? item.quantity;
              final newPrice =
                  double.tryParse(priceController.text) ?? item.unitPrice;

              if (newQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La cantidad debe ser mayor a 0'),
                  ),
                );
                return;
              }

              setState(() {
                _invoiceItems[index] = InvoiceItem(
                  description: item.description,
                  quantity: newQty,
                  unitPrice: newPrice,
                  taxType: item.taxType,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final provider = context.read<BillingProvider>();
    // Load products if not loaded
    if (provider.productsCatalog.isEmpty && _company != null) {
      provider.loadProductsCatalog(_company!.id, branchId: _branch?.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height for tabs
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.7,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Agregar Item',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: 'Servicios', icon: Icon(Icons.cleaning_services)),
                  Tab(text: 'Productos', icon: Icon(Icons.shopping_bag)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [_servicesListWidget(), _productsListWidget()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget Wrapper
  Widget _servicesListWidget() {
    return Builder(builder: (context) => _buildServicesList(context));
  }

  Widget _productsListWidget() {
    return Builder(builder: (context) => _buildProductsList(context));
  }

  Widget _buildServicesList(BuildContext context) {
    final provider = context.watch<BillingProvider>();
    final catalog = provider.washTypesCatalog;
    final vehicleType = widget.vehicle.vehicleType ?? 'turismo';

    if (catalog.isEmpty) {
      return const Center(child: Text('No hay servicios disponibles'));
    }

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: catalog.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final service = catalog[index];
        final name = service['nombre'] ?? 'Servicio';
        final prices = service['precios'] as Map<String, dynamic>?;
        final price = (prices?[vehicleType] ?? 0).toDouble();

        return ListTile(
          leading: const Icon(Icons.local_car_wash),
          title: Text(name),
          subtitle: Text('Precio: L. ${price.toStringAsFixed(2)}'),
          onTap: () {
            setState(() {
              _invoiceItems.add(
                InvoiceItem(
                  description: name,
                  unitPrice: price,
                  quantity: 1,
                  taxType: '15',
                ),
              );
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildProductsList(BuildContext context) {
    final provider = context.watch<BillingProvider>();
    final products = provider.productsCatalog;

    if (products.isEmpty) {
      return const Center(child: Text('No hay productos disponibles'));
    }

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final name = product['nombre'] ?? 'Producto';
        final price = (product['precio'] ?? 0).toDouble();

        return ListTile(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: Text(name),
          subtitle: Text('Precio: L. ${price.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
            onPressed: () {
              setState(() {
                _invoiceItems.add(
                  InvoiceItem(
                    description: name,
                    unitPrice: price,
                    quantity: 1,
                    taxType: '15',
                  ),
                );
              });
              Navigator.pop(context);
            },
          ),
          onTap: () {
            setState(() {
              _invoiceItems.add(
                InvoiceItem(
                  description: name,
                  unitPrice: price,
                  quantity: 1,
                  taxType: '15',
                ),
              );
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _processAndSave() async {
    try {
      if (_company == null || _client == null) {
        throw Exception("Datos incompletos");
      }

      setState(() => _isProcessing = true);

      // Save RTN and Address to client if they were entered and are different
      final newRtn = _rtnController.text.trim();
      final newAddress = _clientAddressController.text.trim();
      final shouldUpdateClient =
          (newRtn.isNotEmpty && newRtn != (_client!.rtn ?? '')) ||
          (newAddress.isNotEmpty && newAddress != (_client!.address ?? ''));

      if (shouldUpdateClient) {
        final updatedClient = _client!.copyWith(
          rtn: newRtn.isNotEmpty ? newRtn : _client!.rtn,
          address: newAddress.isNotEmpty ? newAddress : _client!.address,
          updatedBy: context.read<AuthProvider>().currentUser?.id,
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        await context.read<VehicleEntryRepository>().saveClient(updatedClient);

        // Update local state
        _client = updatedClient;
      }

      // Delegate to Provider
      if (!mounted) return;
      final invoice = await context.read<BillingProvider>().emitInvoice(
        vehicle: widget.vehicle,
        client: _client!,
        company: _company!,
        branch: _branch,
        issuer: context.read<AuthProvider>().currentUser!,
        rtn: _rtnController.text,
        items: _invoiceItems,
        docType: _selectedDocType,
        paymentCondition: _paymentCondition,
        dueDate: _paymentCondition == 'credito' ? _dueDate : null,
      );

      // 5. Generate PDF
      // Note: Fiscal config might have been updated during emitInvoice, but we passed checks
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      final fiscalConfig = context.read<BillingProvider>().fiscalConfig;

      final pdfBytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        company: _company!,
        branch: _branch,
        logoBytes: null, // Configurar logo posteriormente
        fiscalConfig: fiscalConfig,
        client: _client,
        vehicle: widget.vehicle,
      );

      if (!context.mounted) return;

      // 6. Print/Show/Share PDF
      final fileNamePrefix = _selectedDocType == 'invoice'
          ? 'factura'
          : 'recibo';
      final pdfFile = await PdfService.savePdfFile(
        '${fileNamePrefix}_${invoice.createdAt.millisecondsSinceEpoch}.pdf',
        pdfBytes,
      );

      if (!context.mounted) return;
      if (!context.mounted) return;
      // Share via WhatsApp/System
      await PdfService.sharePdf(
        pdfFile,
        'Adjunto su documento de CarWash (Factura/Recibo)',
      );

      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura Emitida y Enviada')),
      );
      // ignore: use_build_context_synchronously
      context.go('/home');
    } catch (e) {
      if (context.mounted) {
        // Show clearer error message
        String msg = e.toString().replaceAll('Exception: ', '');
        _showFiscalError('Error', msg);
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showFiscalError(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
