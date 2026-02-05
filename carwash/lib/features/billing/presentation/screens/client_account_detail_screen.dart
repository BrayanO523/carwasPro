import 'package:carwash/features/billing/domain/entities/invoice.dart';

import 'package:carwash/features/entry/domain/entities/client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/billing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:carwash/core/utils/pdf_service.dart';
import 'register_payment_modal.dart';
import 'client_payment_history_screen.dart';

class ClientAccountDetailScreen extends StatefulWidget {
  final Client client;

  const ClientAccountDetailScreen({super.key, required this.client});

  @override
  State<ClientAccountDetailScreen> createState() =>
      _ClientAccountDetailScreenState();
}

class _ClientAccountDetailScreenState extends State<ClientAccountDetailScreen> {
  bool _isLoading = true;
  List<Invoice> _pendingInvoices = [];
  String _sortOption = 'Vencimiento (Asc)'; // Default sort

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<BillingProvider>();
    final auth = context.read<AuthProvider>();
    final companyId = auth.currentUser?.companyId ?? '';

    if (companyId.isNotEmpty) {
      final invoices = await provider.getPendingInvoicesByClient(
        widget.client.id,
        companyId,
      );
      if (mounted) {
        setState(() {
          _pendingInvoices = invoices;
          _isLoading = false;
          _applySort();
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySort() {
    switch (_sortOption) {
      case 'Vencimiento (Asc)':
        _pendingInvoices.sort(
          (a, b) => (a.dueDate ?? DateTime(2100)).compareTo(
            b.dueDate ?? DateTime(2100),
          ),
        );
        break;
      case 'Vencimiento (Desc)':
        _pendingInvoices.sort(
          (a, b) => (b.dueDate ?? DateTime(2100)).compareTo(
            a.dueDate ?? DateTime(2100),
          ),
        );
        break;
      case 'Monto (Mayor)':
        _pendingInvoices.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'Monto (Menor)':
        _pendingInvoices.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }
  }

  double get _totalDebt => _pendingInvoices.fold(
    0.0,
    (sum, item) => sum + (item.totalAmount - item.paidAmount),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estado de Cuenta', style: GoogleFonts.outfit()),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientPaymentHistoryScreen(
                    clientId: widget.client.id,
                    clientName: widget.client.fullName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Pagos',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildClientHeader(),
                    const SizedBox(height: 16),
                    _buildCreditSummaryCard(),
                    const SizedBox(height: 24),
                    _buildInvoicesHeader(),
                    const SizedBox(height: 12),
                    _buildInvoicesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClientHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            widget.client.fullName.isNotEmpty
                ? widget.client.fullName[0].toUpperCase()
                : '?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.client.fullName,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.client.phone.isNotEmpty)
                Text(
                  widget.client.phone,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'CREDITO PENDIENTE',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'L. ${_totalDebt.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_pendingInvoices.length} Facturas Pendientes',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateAccountStatement,
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                      label: const Text(
                        'ESTADO CUENTA',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showGlobalPaymentModal,
                      icon: const Icon(Icons.payments, size: 18),
                      label: const Text(
                        'ABONAR',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Facturas',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
          value: _sortOption,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue.shade700),
          underline: Container(),
          icon: const Icon(Icons.sort, size: 16),
          items: [
            'Vencimiento (Asc)',
            'Vencimiento (Desc)',
            'Monto (Mayor)',
            'Monto (Menor)',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _sortOption = val;
                _applySort();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildInvoicesList() {
    if (_pendingInvoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade200,
              ),
              const SizedBox(height: 16),
              const Text('El cliente está al día.'),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingInvoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final invoice = _pendingInvoices[index];
        final pending = invoice.totalAmount - invoice.paidAmount;
        final isOverdue =
            invoice.dueDate != null &&
            DateTime.now().isAfter(invoice.dueDate!) &&
            pending > 0;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            side: isOverdue
                ? BorderSide(color: Colors.red.shade200)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  'Factura #${invoice.invoiceNumber}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Emisión: ${DateFormat('dd/MM/yyyy').format(invoice.createdAt)}',
                    ),
                    if (invoice.dueDate != null)
                      Text(
                        'Vence: ${DateFormat('dd/MM/yyyy').format(invoice.dueDate!)}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey.shade700,
                          fontWeight: isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'L. ${pending.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isOverdue ? Colors.red.shade700 : Colors.black87,
                      ),
                    ),
                    Text(
                      'de L. ${invoice.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () => _showInvoiceActions(invoice),
              ),
              const Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _generateAndSharePdf(invoice),
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'PDF',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showRegisterPayment(invoice),
                    icon: const Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: Colors.green,
                    ),
                    label: const Text(
                      'Pagar',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInvoiceActions(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Generar PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _generateAndSharePdf(invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('Abonar a esta Factura'),
              onTap: () {
                Navigator.pop(ctx);
                _showRegisterPayment(invoice);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Actions Reused/Adapted ---

  void _showGlobalPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RegisterPaymentModal(
        client: widget.client,
        totalDebt: _totalDebt,
        pendingInvoices: _pendingInvoices,
        onPaymentSuccess: () {
          _loadData(); // Reload full list and new balance
        },
      ),
    );
  }

  void _showRegisterPayment(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RegisterPaymentModal(
        invoice: invoice,
        onPaymentSuccess: () {
          _loadData(); // Reload full list
        },
      ),
    );
  }

  Future<void> _generateAndSharePdf(Invoice invoice) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final billingProvider = context.read<BillingProvider>();
      final authProvider = context.read<AuthProvider>();

      final companyId = invoice.companyId.isNotEmpty
          ? invoice.companyId
          : (authProvider.currentUser?.companyId ?? '');

      final company = await billingProvider.getCompanyById(companyId);
      if (company == null) throw Exception('Empresa no encontrada');

      final branchId = invoice.branchId.isNotEmpty
          ? invoice.branchId
          : (authProvider.currentUser?.branchId ?? '');
      final branch = await billingProvider.getBranchById(branchId);
      final fiscalConfig = billingProvider.fiscalConfig;

      final pdfBytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        company: company,
        branch: branch,
        fiscalConfig: fiscalConfig,
      );

      if (mounted) Navigator.pop(context);

      final fileName = 'Doc_${invoice.invoiceNumber}.pdf';
      final file = await PdfService.savePdfFile(fileName, pdfBytes);

      await PdfService.sharePdf(
        file,
        'Compartiendo documento ${invoice.invoiceNumber}',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAccountStatement() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final billingProvider = context.read<BillingProvider>();
      final authProvider = context.read<AuthProvider>();
      final companyId = authProvider.currentUser?.companyId ?? '';

      final company = await billingProvider.getCompanyById(companyId);
      if (company == null) throw Exception('Empresa no encontrada');

      // Use the invoices currently loaded in the screen
      final pdfBytes = await PdfService.generateAccountStatement(
        company: company,
        client: widget.client,
        invoices: _pendingInvoices,
        totalDebt: _totalDebt,
      );

      if (mounted) Navigator.pop(context);

      final fileName =
          'EstadoCuenta_${widget.client.fullName.replaceAll(' ', '_')}.pdf';
      final file = await PdfService.savePdfFile(fileName, pdfBytes);

      await PdfService.sharePdf(
        file,
        'Estado de Cuenta - ${widget.client.fullName}',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar Reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
