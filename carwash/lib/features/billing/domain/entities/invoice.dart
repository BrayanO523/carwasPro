import 'invoice_item.dart';

class Invoice {
  final String id;
  final String companyId;
  final String branchId;
  final String clientId;
  final String vehicleId;
  final String clientName;
  final String? clientRtn;
  final double totalAmount;
  final double subtotal; // Base amount before tax
  final double discountTotal;
  final double exemptAmount; // Importe Exento
  final double taxableAmount15; // Importe Gravado 15%
  final double taxableAmount18; // Importe Gravado 18%
  final double isv15; // ISV 15%
  final double isv18; // ISV 18%

  // Compatibility getter
  double get isv => isv15 + isv18;

  final List<InvoiceItem> items;
  final DateTime createdAt;
  final String invoiceNumber;
  final String documentType; // 'invoice' or 'receipt'
  final String? cai; // To track which CAI was used
  final DateTime? caiDeadline;
  final int? rangeMin;
  final int? rangeMax;
  final int? sequenceNumber; // Specific sequence used

  Invoice({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.clientId,
    required this.vehicleId,
    required this.clientName,
    this.clientRtn,
    required this.totalAmount,
    required this.subtotal,
    this.discountTotal = 0.0,
    this.exemptAmount = 0.0,
    this.taxableAmount15 = 0.0,
    this.taxableAmount18 = 0.0,
    this.isv15 = 0.0,
    this.isv18 = 0.0,
    required this.items,
    required this.createdAt,
    required this.invoiceNumber,
    required this.documentType,
    this.cai,
    this.caiDeadline,
    this.rangeMin,
    this.rangeMax,
    this.sequenceNumber,
  });
}
