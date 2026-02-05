import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/billing/domain/entities/invoice.dart';

class ExportService {
  Future<void> exportInvoicesToPdf(
    List<Invoice> invoices, {
    String title = 'Reporte de Facturas',
    String? branchName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');

    // Calculate totals
    final totalAmount = invoices.fold<double>(
      0,
      (sum, inv) => sum + inv.totalAmount,
    );
    final totalPaid = invoices.fold<double>(
      0,
      (sum, inv) => sum + inv.paidAmount,
    );
    final totalPending = totalAmount - totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(title, branchName, startDate, endDate, dateOnlyFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary Row
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem(
                  'Total Facturado',
                  'L. ${totalAmount.toStringAsFixed(2)}',
                ),
                _summaryItem(
                  'Total Pagado',
                  'L. ${totalPaid.toStringAsFixed(2)}',
                ),
                _summaryItem(
                  'Pendiente',
                  'L. ${totalPending.toStringAsFixed(2)}',
                  isHighlight: totalPending > 0,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Invoice Table
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 24,
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Fecha
              1: const pw.FlexColumnWidth(2), // Numero
              2: const pw.FlexColumnWidth(3), // Cliente
              3: const pw.FlexColumnWidth(1.5), // Tipo
              4: const pw.FlexColumnWidth(1.5), // Total
              5: const pw.FlexColumnWidth(1.5), // Pagado
              6: const pw.FlexColumnWidth(1.5), // Estado
            },
            headers: [
              'Fecha',
              'Número',
              'Cliente',
              'Tipo',
              'Total',
              'Pagado',
              'Estado',
            ],
            data: invoices
                .map(
                  (inv) => [
                    dateFormat.format(inv.createdAt),
                    inv.invoiceNumber,
                    inv.clientName,
                    inv.paymentCondition.toUpperCase(),
                    'L. ${inv.totalAmount.toStringAsFixed(2)}',
                    'L. ${inv.paidAmount.toStringAsFixed(2)}',
                    inv.paymentStatus.toUpperCase(),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    // Trigger print/share dialog
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'reporte_facturas.pdf',
    );
  }

  Future<void> exportAccountsReceivableToPdf(
    List<Map<String, dynamic>> groupedClients, {
    String title = 'Cuentas por Cobrar',
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Calculate total debt
    final totalDebt = groupedClients.fold<double>(
      0,
      (sum, c) => sum + (c['totalDebt'] as double),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generado: ${dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(),
          ],
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL CUENTAS POR COBRAR',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'L. ${totalDebt.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: PdfColors.red,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Table
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 28,
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Cliente
              1: const pw.FlexColumnWidth(2), // RTN
              2: const pw.FlexColumnWidth(1), // Facturas
              3: const pw.FlexColumnWidth(2), // Deuda
              4: const pw.FlexColumnWidth(2), // Antigüedad
            },
            headers: [
              'Cliente',
              'RTN',
              'Facturas',
              'Deuda Total',
              'Más Antigua',
            ],
            data: groupedClients
                .map(
                  (c) => [
                    c['clientName'] ?? '',
                    c['clientRtn'] ?? '',
                    c['invoiceCount'].toString(),
                    'L. ${(c['totalDebt'] as double).toStringAsFixed(2)}',
                    c['oldestDueDate'] != null
                        ? dateFormat.format(c['oldestDueDate'] as DateTime)
                        : 'N/A',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'cuentas_por_cobrar.pdf',
    );
  }

  // Helper Widgets
  pw.Widget _buildHeader(
    String title,
    String? branchName,
    DateTime? startDate,
    DateTime? endDate,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        if (branchName != null)
          pw.Text(
            'Sucursal: $branchName',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        if (startDate != null && endDate != null)
          pw.Text(
            'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        pw.Text(
          'Generado: ${dateFormat.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _summaryItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight ? PdfColors.red : PdfColors.black,
          ),
        ),
      ],
    );
  }
}
