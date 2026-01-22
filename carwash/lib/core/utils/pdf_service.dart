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
                            'CAI: ${fiscalConfig.cai}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            'Rango: ${fiscalConfig.rangeMin} al ${fiscalConfig.rangeMax}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            'Fecha Límite: ${DateFormat('dd/MM/yyyy').format(fiscalConfig.deadline)}',
                            style: const pw.TextStyle(fontSize: 9),
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
                          pw.Text(
                            'RTN: ${invoice.clientRtn ?? "Consumidor Final"}',
                          ),
                          if (client != null && client.address != null)
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
                              'VEHÍCULO: ${vehicle.plate ?? "S/P"} - ${vehicle.model ?? ""}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
