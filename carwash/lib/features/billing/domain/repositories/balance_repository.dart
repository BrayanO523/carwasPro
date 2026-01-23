import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/invoice.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/fiscal_config_model.dart';
import '../entities/fiscal_config.dart';

abstract class BalanceRepository {
  Future<void> saveInvoice(Invoice invoice);
  Future<PaginatedInvoices> getInvoices(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DocumentSnapshot? startAfter,
  });
  Future<FiscalConfig?> getFiscalConfig(String companyId, String? branchId);
  Future<void> saveFiscalConfig(FiscalConfig config);
}

class PaginatedInvoices {
  final List<Invoice> items;
  final DocumentSnapshot? lastDocument;

  PaginatedInvoices(this.items, this.lastDocument);
}

class BalanceRepositoryImpl implements BalanceRepository {
  final FirebaseFirestore _firestore;

  BalanceRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveInvoice(Invoice invoice) async {
    // Convert entity to model to access toMap
    final model = invoice is InvoiceModel
        ? invoice
        : InvoiceModel(
            id: invoice.id,
            companyId: invoice.companyId,
            branchId: invoice.branchId,
            clientId: invoice.clientId,
            vehicleId: invoice.vehicleId,
            clientName: invoice.clientName,
            clientRtn: invoice.clientRtn,
            totalAmount: invoice.totalAmount,
            subtotal: invoice.subtotal,
            discountTotal: invoice.discountTotal,
            exemptAmount: invoice.exemptAmount,
            taxableAmount15: invoice.taxableAmount15,
            taxableAmount18: invoice.taxableAmount18,
            isv15: invoice.isv15,
            isv18: invoice.isv18,
            items: invoice.items,
            createdAt: invoice.createdAt,
            invoiceNumber: invoice.invoiceNumber,
            documentType: invoice.documentType,
          );

    await _firestore.collection('facturas').doc(invoice.id).set(model.toMap());
  }

  @override
  Future<PaginatedInvoices> getInvoices(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('facturas')
        .where('empresa_id', isEqualTo: companyId)
        .orderBy('fecha_creacion', descending: true);

    if (startDate != null) {
      query = query.where(
        'fecha_creacion',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      query = query.where(
        'fecha_creacion',
        isLessThanOrEqualTo: Timestamp.fromDate(end),
      );
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Fetch limit + 1 to check if there are more
    query = query.limit(limit);

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => InvoiceModel.fromFirestore(doc))
        .toList();

    return PaginatedInvoices(
      items,
      snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  @override
  Future<FiscalConfig?> getFiscalConfig(
    String companyId,
    String? branchId,
  ) async {
    Query query = _firestore
        .collection('facturacion')
        .where('empresa_id', isEqualTo: companyId);

    if (branchId != null) {
      query = query.where('sucursal_id', isEqualTo: branchId);
    }

    final snapshot = await query.limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return FiscalConfigModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  @override
  Future<void> saveFiscalConfig(FiscalConfig config) async {
    final model = config is FiscalConfigModel
        ? config
        : FiscalConfigModel(
            id: config.id,
            companyId: config.companyId,
            branchId: config.branchId,
            cai: config.cai,
            rtn: config.rtn,
            rangeMin: config.rangeMin,
            rangeMax: config.rangeMax,
            currentSequence: config.currentSequence,
            deadline: config.deadline,
            email: config.email,
            phone: config.phone,
            address: config.address,
          );

    if (config.id.isEmpty) {
      await _firestore.collection('facturacion').add(model.toMap());
    } else {
      await _firestore
          .collection('facturacion')
          .doc(config.id)
          .set(model.toMap());
    }
  }
}
