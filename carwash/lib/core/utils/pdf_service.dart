import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../features/company/domain/entities/company.dart';
import '../../features/branch/domain/entities/branch.dart';
import '../../features/entry/domain/entities/client.dart';
import '../../features/entry/domain/entities/vehicle.dart';
import '../../features/billing/domain/entities/invoice.dart';
import '../../features/billing/domain/entities/fiscal_config.dart';
import 'package:carwash/core/utils/number_to_words.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Company company,
    required Branch? branch,
    required FiscalConfig? fiscalConfig,
    Uint8List? logoBytes,
    // Helper objects for extra details not in Invoice snapshot (optional)
    Client? client,
    Vehicle? vehicle,
  }) async {
    final pdf = pw.Document();
    final dateFormatted = DateFormat('dd/MM/yyyy').format(invoice.createdAt);
    final isInvoice = invoice.documentType == 'invoice';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and Company Info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoBytes != null)
                          pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 80,
                            height: 80,
                          ),
                        pw.Text(
                          company.name.toUpperCase(),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        pw.Text('RTN: ${company.rtn}'),
                        pw.Text(
                          'Dirección: ${branch?.address ?? company.address}',
                        ),
                        pw.Text('Tel: ${branch?.phone ?? company.phone}'),
                        pw.Text('Email: ${company.email}'),
                      ],
                    ),
                  ),
                  // Fiscal Info Box (SAR)
                  if (isInvoice && fiscalConfig != null)
                    pw.Container(
                      width: 200,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'FACTURA',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          pw.Text(
                            'No. ${invoice.invoiceNumber}',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.red,
                            ),
                          ),
                          pw.Divider(height: 8),
                          pw.Text(
                            'CAI: ${fiscalConfig.cai ?? "N/A"}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            'Rango Autorizado:\nDel ${fiscalConfig.establishment ?? "000"}-${fiscalConfig.emissionPoint ?? "001"}-${fiscalConfig.documentType ?? "01"}-${(fiscalConfig.rangeMin ?? 0).toString().padLeft(8, '0')} al ${fiscalConfig.establishment ?? "000"}-${fiscalConfig.emissionPoint ?? "001"}-${fiscalConfig.documentType ?? "01"}-${(fiscalConfig.rangeMax ?? 0).toString().padLeft(8, '0')}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            'Fecha Emisión: ${fiscalConfig.authorizationDate != null ? DateFormat('dd/MM/yyyy').format(fiscalConfig.authorizationDate!) : "N/A"}   Fecha Límite: ${fiscalConfig.deadline != null ? DateFormat('dd/MM/yyyy').format(fiscalConfig.deadline!) : "N/A"}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    )
                  else
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Text(
                        'RECIBO',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Client Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CLIENTE: ${invoice.clientName}'),
                          if (isInvoice)
                            pw.Text(
                              'RTN: ${invoice.clientRtn.isNotEmpty ? invoice.clientRtn : "Consumidor Final"}',
                            ),
                          if (isInvoice &&
                              client != null &&
                              client.address != null)
                            pw.Text('Dirección: ${client.address}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FECHA: $dateFormatted'),
                          if (vehicle != null)
                            pw.Text(
                              'VEHÍCULO: ${(vehicle.vehicleType ?? "").toUpperCase()} ${vehicle.plate != null && vehicle.plate!.isNotEmpty ? "(${vehicle.plate})" : ""}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Payment Info Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'CONDICIÓN DE PAGO: ${invoice.paymentCondition.toUpperCase()}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  if (invoice.paymentCondition == 'credito' &&
                      invoice.dueDate != null)
                    pw.Text(
                      'VENCIMIENTO: ${DateFormat('dd/MM/yyyy').format(invoice.dueDate!)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.red,
                      ),
                    ),
                ],
              ),
              pw.Divider(),

              pw.SizedBox(height: 10),

              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey50,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'DESCRIPCIÓN',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'CANTIDAD',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'PRECIO UNIT.',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'TOTAL',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Body
                  ...invoice.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(item.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${item.quantity}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item.unitPrice.toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item.total.toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Amount in Words
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total en Letras:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          NumberToWords.convert(invoice.totalAmount),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Original: Cliente | Copia: Emisor',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Semantic Totals
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Column(
                        children: [
                          _buildPdfRow('Subtotal Exento', invoice.exemptAmount),
                          _buildPdfRow(
                            'Subtotal Gravado 15%',
                            invoice.taxableAmount15,
                          ),
                          _buildPdfRow(
                            'Subtotal Gravado 18%',
                            invoice.taxableAmount18,
                          ),
                          _buildPdfRow('ISV 15%', invoice.isv15),
                          _buildPdfRow('ISV 18%', invoice.isv18),
                          _buildPdfRow(
                            'Descuento y Rebajas',
                            invoice.discountTotal,
                          ),
                          pw.Divider(),
                          _buildPdfRow(
                            'TOTAL A PAGAR',
                            invoice.totalAmount,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer (LAI/Rules)
              if (isInvoice)
                pw.Center(
                  child: pw.Text(
                    'La factura es beneficio de todos. Exíjala.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfRow(
    String label,
    double value, {
    bool isBold = false,
  }) {
    if (value == 0 && !isBold) return pw.Container();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'L. ${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Simplified save file helper
  static Future<File> savePdfFile(String fileName, Uint8List bytes) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> sharePdf(File file, String text) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }

  static Future<Uint8List> generateAccountStatement({
    required Company company,
    required Client client,
    required List<Invoice> invoices,
    required double totalDebt,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoBytes != null)
                        pw.Image(
                          pw.MemoryImage(logoBytes),
                          width: 80,
                          height: 80,
                        ),
                      pw.Text(
                        company.name.toUpperCase(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      pw.Text('RTN: ${company.rtn}'),
                      pw.Text('Tel: ${company.phone}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ESTADO DE CUENTA',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(now)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Client Info
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLIENTE: ${client.fullName.toUpperCase()}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (client.rtn != null && client.rtn!.isNotEmpty)
                      pw.Text('RTN: ${client.rtn}'),
                    if (client.phone.isNotEmpty)
                      pw.Text('Tel: ${client.phone}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Invoices Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey50,
                    ),
                    children: [
                      _buildHeaderCell('Fecha'),
                      _buildHeaderCell('Factura #'),
                      _buildHeaderCell('Vencimiento'),
                      _buildHeaderCell('Total', align: pw.TextAlign.right),
                      _buildHeaderCell('Saldo', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...invoices.map((invoice) {
                    final pending = invoice.totalAmount - invoice.paidAmount;
                    final isOverdue =
                        invoice.dueDate != null &&
                        now.isAfter(invoice.dueDate!) &&
                        pending > 0;

                    return pw.TableRow(
                      children: [
                        _buildCell(
                          DateFormat('dd/MM/yyyy').format(invoice.createdAt),
                        ),
                        _buildCell(invoice.invoiceNumber),
                        _buildCell(
                          invoice.dueDate != null
                              ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(invoice.dueDate!)
                              : '-',
                          color: isOverdue ? PdfColors.red : PdfColors.black,
                        ),
                        _buildCell(
                          'L. ${invoice.totalAmount.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                        ),
                        _buildCell(
                          'L. ${pending.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),

              // Grand Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL PENDIENTE:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'L. ${totalDebt.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: PdfColors.red,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
