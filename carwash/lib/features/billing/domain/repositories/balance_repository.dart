import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/invoice.dart';
import '../entities/fiscal_config.dart';
import '../entities/payment.dart';

/// Abstract interface for Balance operations (Clean Architecture: Domain Layer)
abstract class BalanceRepository {
  Future<void> saveInvoice(Invoice invoice);
  Future<PaginatedInvoices> getInvoices(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
    String? documentType,
    String? branchId,
    String? cai,
    String? clientId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  });
  Future<FiscalConfig?> getFiscalConfig(
    String companyId,
    String? branchId,
    String? emissionPoint,
  );
  Future<List<FiscalConfig>> getFiscalConfigs(String companyId);
  Future<void> saveFiscalConfig(FiscalConfig config);
  Future<void> archiveFiscalConfig(FiscalConfig config);
  Future<List<FiscalConfig>> getFiscalHistory(
    String companyId,
    String branchId,
  );

  // Credit Methods
  Future<List<Invoice>> getReceivables(String companyId);
  Future<void> updateInvoicePaymentStatus({
    required String invoiceId,
    required String status,
    required double paidAmount,
    required DateTime? paidAt,
    String? userId,
  });
  Future<void> savePayment(Payment payment);
  Future<List<Payment>> getPaymentsByInvoice(
    String invoiceId,
    String companyId,
  );
  Future<List<Payment>> getPaymentsByClient(String clientId, String companyId);
  Future<Invoice?> getInvoiceById(String invoiceId);
}

/// Paginated result for invoices
class PaginatedInvoices {
  final List<Invoice> items;
  final DocumentSnapshot? lastDocument;

  PaginatedInvoices(this.items, this.lastDocument);
}
