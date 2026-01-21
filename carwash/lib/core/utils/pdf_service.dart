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
import '../../features/billing/domain/entities/invoice_item.dart';

class PdfService {
  static Future<File> generateInvoicePdf({
    required Company company,
    required Branch? branch,
    required Client client,
    required Vehicle vehicle,
    required List<InvoiceItem> items,
    required String documentType, // Add documentType
  }) async {
    final pdf = pw.Document();
    final date = DateTime.now();
    final dateFormatted = DateFormat('dd/MM/yyyy').format(date);
    final isInvoice = documentType == 'invoice';

    // Calculate Totals
    final subtotal = items.fold(0.0, (sum, item) => sum + item.price);
    final isv = subtotal * 0.15;
    final total = subtotal + isv;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      company.name.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (isInvoice) ...[
                      pw.Text('RTN: ${company.rtn}'),
                      pw.Text(
                        'Dirección: ${branch?.address ?? company.address}',
                      ),
                      pw.Text('Tel: ${branch?.phone ?? company.phone}'),
                      pw.Text('Correo: ${company.email}'),
                      pw.Divider(height: 20),
                      pw.Text(
                        'FACTURA',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      pw.Text('No. 000-001-01-00000123 (Mock)'),
                      pw.Text(
                        'C.A.I.: E4A873-...',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Rango Autorizado: 000-000-01-001 a 000-000-01-100',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Fecha Límite: 31/12/2026',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ] else ...[
                      // Receipt Header
                      pw.Text(
                        'Dirección: ${branch?.address ?? company.address}',
                      ),
                      pw.Text('Tel: ${branch?.phone ?? company.phone}'),
                      pw.Divider(height: 20),
                      pw.Text(
                        'RECIBO',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                    pw.Text('Fecha: $dateFormatted'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Client Info
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(5),
                color: PdfColors.grey200,
                child: pw.Text(
                  'DATOS DEL CLIENTE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Cliente: ${client.name} ${client.lastName}'),
              if (client.rtn != null && client.rtn!.isNotEmpty)
                pw.Text('RTN: ${client.rtn}'),
              pw.Text('Vehículo: ${vehicle.plate ?? "S/P"} (${vehicle.model})'),

              pw.SizedBox(height: 20),

              // Items Table
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(5),
                color: PdfColors.grey200,
                child: pw.Text(
                  'DETALLE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Descripción',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Cant.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Total',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Items
                  ...items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(item.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('1', textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'L. ${item.price.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 10),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal:  L. ${subtotal.toStringAsFixed(2)}'),
                      pw.Text('Descuento:  L. 0.00'),
                      pw.Text('ISV (15%):  L. ${isv.toStringAsFixed(2)}'),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'TOTAL A PAGAR:  L. ${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  '¡Gracias por su preferencia!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/factura_${vehicle.plate ?? "vehiculo"}_${date.millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> sharePdf(File file, String text) async {
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
