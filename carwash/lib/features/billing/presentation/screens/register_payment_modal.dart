import 'package:carwash/features/entry/domain/entities/client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/invoice.dart';
import '../providers/billing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RegisterPaymentModal extends StatefulWidget {
  final Invoice? invoice;
  final Client? client;
  final double? totalDebt; // Required if client global payment
  final List<Invoice>? pendingInvoices; // Required for global payment preview
  final VoidCallback onPaymentSuccess;

  const RegisterPaymentModal({
    super.key,
    this.invoice,
    this.client,
    this.totalDebt,
    this.pendingInvoices,
    required this.onPaymentSuccess,
  }) : assert(
         invoice != null || client != null,
         'Must provide Invoice OR Client',
       );

  @override
  State<RegisterPaymentModal> createState() => _RegisterPaymentModalState();
}

class _RegisterPaymentModalState extends State<RegisterPaymentModal> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'efectivo';
  bool _isProcessing = false;
  late double _remainingBalance;
  List<Map<String, dynamic>> _preview = [];

  String? _amountError;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _remainingBalance =
          widget.invoice!.totalAmount - widget.invoice!.paidAmount;
      _amountController.text = _remainingBalance.toStringAsFixed(2);
    } else {
      _remainingBalance = widget.totalDebt ?? 0.0;
      _amountController.text = ''; // Start empty for global payment
    }

    _amountController.addListener(_validateAmount);
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateAmount);
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateAmount() {
    final text = _amountController.text;
    if (text.isEmpty) {
      if (mounted) setState(() => _amountError = 'Requerido');
      return;
    }

    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      if (mounted) setState(() => _amountError = 'Monto inválido');
      return;
    }

    if (amount > _remainingBalance + 0.01) {
      if (mounted) {
        setState(() => _amountError = 'El monto excede el saldo pendiente');
      }
      return;
    }

    if (mounted && _amountError != null) {
      setState(() => _amountError = null);
    }

    // Calculate preview for global payment
    if (widget.client != null && widget.pendingInvoices != null) {
      _calculatePreview(amount);
    }
  }

  void _calculatePreview(double paymentAmount) {
    if (paymentAmount <= 0) {
      setState(() => _preview = []);
      return;
    }

    final sorted = List<Invoice>.from(widget.pendingInvoices!);
    // Sort by Due Date ASC (Oldest first) - Matching Provider Logic
    sorted.sort((a, b) {
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    double remaining = paymentAmount;
    List<Map<String, dynamic>> tempPreview = [];

    for (var invoice in sorted) {
      if (remaining <= 0.001) break;

      final pending = invoice.totalAmount - invoice.paidAmount;
      if (pending <= 0) continue;

      final payAmount = (remaining >= pending) ? pending : remaining;

      tempPreview.add({
        'invoice': invoice.invoiceNumber,
        'docType': invoice.documentType,
        'originalPending': pending,
        'payment': payAmount,
        'newBalance': pending - payAmount,
      });

      remaining -= payAmount;
    }

    setState(() => _preview = tempPreview);
  }

  Future<void> _processPayment() async {
    // Final validation before submit
    _validateAmount();
    if (_amountError != null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() => _isProcessing = true);

    try {
      final user = context.read<AuthProvider>().currentUser;
      final billingProvider = context.read<BillingProvider>();

      if (user == null) throw Exception('No session');

      if (widget.invoice != null) {
        // Single Invoice Payment
        await billingProvider.registerPayment(
          invoice: widget.invoice!,
          amount: amount,
          paymentMethod: _paymentMethod,
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          user: user,
        );
      } else if (widget.client != null) {
        // Global Client Payment
        await billingProvider.registerGlobalPayment(
          clientId: widget.client!.id,
          companyId: widget.client!.companyId,
          amount: amount,
          paymentMethod: _paymentMethod,
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          user: user,
        );
      }

      if (mounted) {
        widget.onPaymentSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGlobal = widget.client != null;
    final title = isGlobal ? 'Registrar Abono Global' : 'Registrar Abono';
    final subtitle = isGlobal
        ? widget.client!.fullName
        : widget.invoice!.invoiceNumber;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isGlobal
                                ? 'DEUDA TOTAL PENDIENTE'
                                : 'SALDO PENDIENTE FACTURA',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'L. ${_remainingBalance.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isGlobal
                                ? 'Se abonará a las facturas más antiguas primero.'
                                : 'Total Factura: L. ${widget.invoice!.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form
                    const Text(
                      'Nuevo Pago',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Monto a Abonar',
                        prefixText: 'L. ',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        errorText: _amountError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_paymentMethod),
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'efectivo',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'transferencia',
                          child: Text('Transferencia'),
                        ),
                        DropdownMenuItem(
                          value: 'tarjeta',
                          child: Text('Tarjeta'),
                        ),
                        DropdownMenuItem(
                          value: 'cheque',
                          child: Text('Cheque'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Referencia (Opcional)',
                        hintText: 'Nº Cheque, Transf.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (Opcional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isProcessing || _amountError != null
                          ? null
                          : _processPayment,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'REGISTRAR PAGO',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 20),
                    if (_preview.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        'Distribución del Abono (FIFO)',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2), // Factura
                            1: FlexColumnWidth(1.5), // Saldo
                            2: FlexColumnWidth(1.5), // Abono
                            3: FlexColumnWidth(1.5), // Nuevo
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Factura',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Saldo',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Abono',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Resto',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ..._preview.map((item) {
                              final isPaid =
                                  (item['newBalance'] as double) <= 0.01;
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['invoice'],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          item['docType'] == 'invoice'
                                              ? 'Factura'
                                              : 'Recibo',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      (item['originalPending'] as double)
                                          .toStringAsFixed(2),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      (item['payment'] as double)
                                          .toStringAsFixed(2),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: isPaid
                                        ? const Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: Colors.green,
                                          )
                                        : Text(
                                            (item['newBalance'] as double)
                                                .toStringAsFixed(2),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
