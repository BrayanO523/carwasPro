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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carwash/features/company/domain/entities/company.dart';
import 'package:carwash/features/company/domain/repositories/company_repository.dart';
import 'package:carwash/core/utils/pdf_service.dart';
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
    _rtnController = TextEditingController();
    _emailController = TextEditingController();
    _loadData(); // Load Client and Branch
    _loadInvoiceItems(); // Load Invoice Items
  }

  Future<void> _loadInvoiceItems() async {
    try {
      if (widget.vehicle.services.isEmpty) {
        setState(() => _isLoadingItems = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('tiposLavados')
          .where(FieldPath.documentId, whereIn: widget.vehicle.services)
          .get();

      final vehicleType =
          widget.vehicle.vehicleType ?? 'turismo'; // Default fallback
      final List<InvoiceItem> items = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final prices = data['precios'] as Map<String, dynamic>?;
        final price = (prices?[vehicleType] ?? 0).toDouble();

        items.add(
          InvoiceItem(
            description: data['nombre'] ?? 'Servicio',
            unitPrice: price,
            quantity: 1, // Default quantity
            taxType: '15', // Default tax type
          ),
        );
      }

      if (mounted) {
        setState(() {
          _invoiceItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      print('Error loading invoice items: $e');
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _loadData() async {
    final vehicleRepo = context.read<VehicleEntryRepository>();
    final branchRepo = context.read<BranchRepository>();
    final companyRepo = context.read<CompanyRepository>();
    final authProvider = context.read<AuthProvider>();

    try {
      // 1. Load Client
      final client = await vehicleRepo.getClientById(widget.vehicle.clientId);

      // 2. Load Branch & Company
      Branch? branch;
      Company? company;

      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        // Fetch Company
        company = await companyRepo.getCompany(currentUser.companyId);

        // Fetch Branch
        final branchId = currentUser.branchId;
        if (branchId != null && branchId.isNotEmpty) {
          branch = await branchRepo.getBranch(branchId);
        } else {
          final branches = await branchRepo.getBranches(currentUser.companyId);
          if (branches.isNotEmpty) {
            branch = branches.first;
          }
        }
      }

      if (mounted) {
        setState(() {
          if (client != null) {
            _client = client;
            _rtnController.text = client.rtn ?? '';
            // Address controller removed
            // Email controller not used for input, but maybe we should show it or remove entirely if unused
          }
          _branch = branch;
          _company = company;
          _isLoadingClient = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClient = false;
        });
      }
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
    final authProvider = context.watch<AuthProvider>();
    final companyName = authProvider.companyName ?? 'EMPRESA DEMO';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emitir Factura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to Billing Configuration
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
                  // Document Type Selector
                  _buildDocTypeSelector(),

                  // Invoice Preview Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Center(
                          child: Column(
                            children: [
                              Text(
                                companyName.toUpperCase(),
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('RTN: 08011999123456 (Mock)'),
                              Text(
                                'Dirección: ${_branch?.address ?? _company?.address ?? "Dirección Principal"}',
                              ),
                              Text(
                                'Tel: ${_branch?.phone ?? _company?.phone ?? "(504) 0000-0000"}',
                              ),
                              Text(
                                'Correo: ${_company?.email ?? "info@carwash.com"}',
                              ),
                              const Divider(height: 24),
                              Text(
                                _selectedDocType == 'invoice'
                                    ? 'FACTURA'
                                    : 'RECIBO',
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text('No. 000-001-01-00000123'),
                              Text(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Client Info Section (Editable)
                        _SectionHeader(title: 'DATOS DEL CLIENTE'),
                        const SizedBox(height: 8),
                        Text('Cliente: ${widget.vehicle.clientName}'),
                        if (widget.vehicle.plate != null)
                          Text(
                            'Vehículo: ${widget.vehicle.plate} (${widget.vehicle.model})',
                          ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _rtnController,
                          decoration: const InputDecoration(
                            labelText: 'RTN del Cliente (Opcional)',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Items Table
                        _SectionHeader(title: 'DETALLE'),
                        const SizedBox(height: 8),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(2),
                          },
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          children: [
                            const TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Descripción',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Cant.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Total',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ..._invoiceItems.map((item) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(item.description),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      '1',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'L. ${item.total.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Totals
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Subtotal:  L. ${_subtotal.toStringAsFixed(2)}',
                                ),
                                Text('Descuento:  L. 0.00'),
                                Text(
                                  'ISV (15%):  L. ${_isv15.toStringAsFixed(2)}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'TOTAL A PAGAR:  L. ${_total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 40),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _processInvoice,
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
                          ? 'Procesando...'
                          : 'EMITIR ${_selectedDocType.toUpperCase()}',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: _selectedDocType == 'invoice'
                          ? null
                          : Colors.orange, // Different color for receipt
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _selectedDocType = 'invoice'; // Default

  Widget _buildDocTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'invoice',
            label: Text('FACTURA'),
            icon: Icon(Icons.receipt_long),
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
        style: ButtonStyle(visualDensity: VisualDensity.comfortable),
      ),
    );
  }

  Future<void> _processInvoice() async {
    if (_company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Faltan datos de la empresa')),
      );
      return;
    }

    if (_client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Faltan datos del cliente')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Update Client with new RTN if changed
      if (_client != null) {
        final bool changed = _client!.rtn != _rtnController.text;

        if (changed) {
          final updatedClient = Client(
            id: _client!.id,
            name: _client!.name,
            lastName: _client!.lastName,
            phone: _client!.phone,
            companyId: _client!.companyId,
            rtn: _rtnController.text,
            address: _client!.address, // Keep existing address
            email: _client!.email,
          );

          await context.read<VehicleEntryRepository>().saveClient(
            updatedClient,
          );
          _client = updatedClient;
        }
      }

      // 2. Create and Save Invoice
      final invoice = Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID gen
        companyId: _company!.id,
        branchId: _branch?.id ?? '', // Handle nullable branch
        clientId: _client!.id,
        vehicleId: widget.vehicle.id,
        clientName: _client!.name,
        clientRtn: _client!.rtn,
        totalAmount: _total,
        subtotal: _subtotal,
        discountTotal: _discountTotal,
        exemptAmount: _exemptAmount,
        taxableAmount15: _taxableAmount15,
        taxableAmount18: _taxableAmount18,
        isv15: _isv15,
        isv18: _isv18,
        items: _invoiceItems,
        createdAt: DateTime.now(),
        invoiceNumber:
            '${_selectedDocType == 'invoice' ? 'FAC' : 'REC'}-${DateTime.now().millisecondsSinceEpoch}', // Mock Number
        documentType: _selectedDocType, // Add documentType
      );

      await context.read<BalanceProvider>().createInvoice(invoice);

      // 3. Mark Vehicle as Finished
      await context.read<BillingProvider>().markAsFinished(widget.vehicle.id);

      // 4. Generate PDF
      final pdfFile = await PdfService.generateInvoicePdf(
        company: _company!,
        branch: _branch,
        client: _client!,
        vehicle: widget.vehicle,
        items: _invoiceItems,
        documentType: _selectedDocType,
      );

      // 4. Share PDF
      if (mounted) {
        await PdfService.sharePdf(
          pdfFile,
          'Factura ${_client!.name} - ${widget.vehicle.plate ?? "Vehiculo"}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factura emitida con éxito')),
        );
        Navigator.pop(context); // Close screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al emitir factura: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.grey[200],
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
