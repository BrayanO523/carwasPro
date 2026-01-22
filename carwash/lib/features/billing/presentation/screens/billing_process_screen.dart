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
import 'package:carwash/features/billing/domain/entities/invoice.dart';
import 'package:carwash/features/billing/presentation/providers/balance_provider.dart';

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
    await billingProvider.loadWashTypesCatalog();

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
          }
          _branch = branch;
          _company = company;
          _isLoadingClient = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClient = false);
      print('Error loading data: $e');
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
            SegmentedButton<String>(
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
            const SizedBox(height: 12),
            _buildTextField(_rtnController, 'RTN del Cliente'),
            const SizedBox(height: 12),
            _buildTextField(
              _clientAddressController,
              'Dirección del Consumidor',
            ),
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
                  flex: 3,
                  child: Text(
                    'Descripción',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Cant.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 40), // Space for actions
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
                      flex: 3,
                      // Editable Description could go here, for now static
                      child: Text(item.description),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '1',
                        textAlign: TextAlign.center,
                      ), // Mock Quantity
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'L. ${item.total.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmRemoveItem(index),
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
    if (amount == 0 && !isBold)
      return const SizedBox.shrink(); // Hide 0 sections
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

  void _showAddItemDialog() {
    final provider = context.read<BillingProvider>();
    final catalog = provider.washTypesCatalog;
    final vehicleType = widget.vehicle.vehicleType ?? 'turismo';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Agregar Servicio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: catalog.isEmpty
                ? const Center(child: Text('No hay servicios disponibles'))
                : ListView.separated(
                    itemCount: catalog.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final service = catalog[index];
                      final name = service['nombre'] ?? 'Servicio';
                      final prices =
                          service['precios'] as Map<String, dynamic>?;
                      final price = (prices?[vehicleType] ?? 0).toDouble();

                      return ListTile(
                        leading: const Icon(Icons.local_car_wash),
                        title: Text(name),
                        subtitle: Text(
                          'Precio: L. ${price.toStringAsFixed(2)}',
                        ),
                        onTap: () {
                          // Add Item
                          setState(() {
                            _invoiceItems.add(
                              InvoiceItem(
                                description: name,
                                unitPrice: price,
                                quantity: 1,
                                taxType: '15', // Default 15% ISV
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _processAndSave() async {
    try {
      // Validate
      if (_company == null) throw Exception("Datos de empresa no cargados");

      // Validate Fiscal Data ONLY if Invoice
      // Validate Fiscal Data ONLY if Invoice
      if (_selectedDocType == 'invoice') {
        final fiscalConfig = context.read<BillingProvider>().fiscalConfig;
        if (fiscalConfig == null ||
            fiscalConfig.cai.isEmpty ||
            fiscalConfig.rtn.isEmpty ||
            fiscalConfig.rangeMin.isEmpty ||
            fiscalConfig.rangeMax.isEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Configuración Fiscal Incompleta'),
              content: const Text(
                'Para emitir FACTURAS, necesitas configurar el CAI, RTN y Rangos en la sección de Empresa.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/company-config');
                  },
                  child: const Text('Ir a Configuración'),
                ),
              ],
            ),
          );
          return;
        }
      }

      setState(() => _isProcessing = true);

      // 1. Update/Save Fiscal Config
      // 1. Get Fiscal Config (already validated if invoice)
      final fiscalConfig = context.read<BillingProvider>().fiscalConfig;

      // Note: We don't need to update FiscalConfig here anymore as we aren't editing it.
      // We rely on the one loaded from 'company-config'.
      // EXCEPT: We might need to increment currentSequence, but that should ideally happen in the backend
      // or via a specific method in provider, not by overwriting the whole config with empty controllers.

      // For now, we just proceed to create the invoice using the loaded fiscal data.
      // The updateFiscalConfig call is removed because we are not editing it here.

      // 2. Create Invoice Entity
      final invoice = Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Generated ID
        companyId: _company!.id,
        branchId: _branch?.id ?? '',
        clientId: _client!.id,
        vehicleId: widget.vehicle.id,
        clientName: _client!.name,
        clientRtn: _rtnController.text,
        invoiceNumber:
            '${_selectedDocType == 'invoice' ? 'FAC' : 'REC'}-${DateTime.now().millisecondsSinceEpoch}',

        // CAI/Range passed via fiscalConfig to PDF
        items: _invoiceItems,
        subtotal: _subtotal,
        discountTotal: _discountTotal,

        // Tax Breakdown
        exemptAmount: _exemptAmount,
        taxableAmount15: _taxableAmount15,
        taxableAmount18: _taxableAmount18,
        isv15: _isv15,
        isv18: _isv18,

        totalAmount: _total,
        createdAt: DateTime.now(),
        documentType: _selectedDocType,
      );

      // 3. Save Invoice via Provider
      await context.read<BalanceProvider>().createInvoice(invoice);

      // 4. Mark Vehicle as Finished
      await context.read<BillingProvider>().markAsFinished(widget.vehicle.id);

      // 5. Generate PDF
      final pdfBytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        company: _company!,
        branch: _branch,
        logoBytes: null, // TODO: Load Logo
        fiscalConfig: fiscalConfig, // Pass full fiscal config
      );

      // 6. Print/Show/Share PDF
      final fileNamePrefix = _selectedDocType == 'invoice'
          ? 'factura'
          : 'recibo';
      final pdfFile = await PdfService.savePdfFile(
        '${fileNamePrefix}_${invoice.createdAt.millisecondsSinceEpoch}.pdf',
        pdfBytes,
      );

      if (mounted) {
        // Share via WhatsApp/System
        await PdfService.sharePdf(
          pdfFile,
          'Adjunto su documento de CarWash (Factura/Recibo)',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura Emitida y Enviada')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al emitir factura: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }
}
