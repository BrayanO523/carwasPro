import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/fiscal_config.dart';
import '../../domain/entities/invoice.dart';
import '../providers/billing_provider.dart';

class CaiInvoicesScreen extends StatefulWidget {
  final String companyId;
  final FiscalConfig fiscalConfig;

  const CaiInvoicesScreen({
    super.key,
    required this.companyId,
    required this.fiscalConfig,
  });

  @override
  State<CaiInvoicesScreen> createState() => _CaiInvoicesScreenState();
}

class _CaiInvoicesScreenState extends State<CaiInvoicesScreen> {
  bool _isLoading = true;
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final provider = context.read<BillingProvider>();
    final cai = widget.fiscalConfig.cai;

    if (cai == null || cai.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final invoices = await provider.getInvoicesByCai(widget.companyId, cai);

    if (mounted) {
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Facturas por CAI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // CAI Info Header
          _buildCaiHeader(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron facturas\npara este rango CAI',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      return _buildInvoiceCard(invoice);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaiHeader() {
    final config = widget.fiscalConfig;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAI SELECCIONADO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            config.cai ?? 'N/A',
            style: GoogleFonts.robotoMono(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rango: ${config.rangeMin ?? 0} - ${config.rangeMax ?? 0}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Total Generado: ${_invoices.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.receipt_long, color: Colors.blue, size: 20),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              invoice.clientName,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'L. ${invoice.totalAmount.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: invoice.paymentCondition == 'contado'
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                invoice.paymentCondition.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: invoice.paymentCondition == 'contado'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
