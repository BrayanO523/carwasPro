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
  final double subtotal;
  final double isv;
  final List<InvoiceItem> items;
  final DateTime createdAt;
  final String invoiceNumber;
  final String documentType; // 'invoice' or 'receipt'

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
    required this.isv,
    required this.items,
    required this.createdAt,
    required this.invoiceNumber,
    required this.documentType,
  });
}
