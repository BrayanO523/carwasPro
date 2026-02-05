import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/payment.dart';

import '../providers/billing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ClientPaymentHistoryScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientPaymentHistoryScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientPaymentHistoryScreen> createState() =>
      _ClientPaymentHistoryScreenState();
}

class _ClientPaymentHistoryScreenState
    extends State<ClientPaymentHistoryScreen> {
  bool _isLoading = true;
  List<Payment> _payments = [];

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
      final payments = await provider.getPaymentsByClient(
        widget.clientId,
        companyId,
      );
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Pagos',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.clientName,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay pagos registrados',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _payments.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final payment = _payments[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(payment.createdAt),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Text(
                                payment.paymentMethod.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (payment.reference != null &&
                                    payment.reference!.isNotEmpty)
                                  Text(
                                    'Ref: ${payment.reference}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                if (payment.notes != null &&
                                    payment.notes!.isNotEmpty)
                                  Text(
                                    payment.notes!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                // We could try to show invoice number if invoiceId matches known pattern or if we want to fetch it
                                // But for now keeping it simple as per plan.
                              ],
                            ),
                            Text(
                              'L. ${payment.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
