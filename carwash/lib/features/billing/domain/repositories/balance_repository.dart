import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/invoice.dart';
import '../../data/models/invoice_model.dart';

abstract class BalanceRepository {
  Future<void> saveInvoice(Invoice invoice);
  Future<List<Invoice>> getInvoices(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
  });
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
            isv: invoice.isv,
            items: invoice.items,
            createdAt: invoice.createdAt,
            invoiceNumber: invoice.invoiceNumber,
            documentType: invoice.documentType,
          );

    await _firestore.collection('facturas').doc(invoice.id).set(model.toMap());
  }

  @override
  Future<List<Invoice>> getInvoices(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
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

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => InvoiceModel.fromFirestore(doc)).toList();
  }
}
