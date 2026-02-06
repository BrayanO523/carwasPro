import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/fiscal_config.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/balance_repository.dart';
import '../models/invoice_model.dart';
import '../models/fiscal_config_model.dart';

/// Firestore implementation of BalanceRepository (Clean Architecture: Data Layer)
class BalanceRepositoryImpl implements BalanceRepository {
  final FirebaseFirestore _firestore;

  BalanceRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveInvoice(Invoice invoice) async {
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
            cai: invoice.cai,
            caiDeadline: invoice.caiDeadline,
            rangeMin: invoice.rangeMin,
            rangeMax: invoice.rangeMax,
            sequenceNumber: invoice.sequenceNumber,
            paymentCondition: invoice.paymentCondition,
            paymentStatus: invoice.paymentStatus,
            dueDate: invoice.dueDate,
            paidAmount: invoice.paidAmount,
            paidAt: invoice.paidAt,
            createdBy: invoice.createdBy,
            updatedBy: invoice.updatedBy,
            updatedAt: invoice.updatedAt,
          );

    await _firestore.collection('facturas').doc(invoice.id).set(model.toMap());
  }

  @override
  Future<List<Invoice>> getReceivables(String companyId) async {
    final snapshot = await _firestore
        .collection('facturas')
        .where('empresa_id', isEqualTo: companyId)
        .where('condicion_pago', isEqualTo: 'credito')
        .where('estado_pago', whereIn: ['pendiente', 'parcial', 'vencido'])
        .orderBy('fecha_creacion', descending: true)
        .get();

    return snapshot.docs.map((doc) => InvoiceModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateInvoicePaymentStatus({
    required String invoiceId,
    required String status,
    required double paidAmount,
    required DateTime? paidAt,
    String? userId,
  }) async {
    final updates = <String, dynamic>{
      'estado_pago': status,
      'monto_pagado': paidAmount,
      'updatedBy': userId,
      'updatedAt': Timestamp.now(),
    };
    if (paidAt != null) {
      updates['fecha_pagado'] = Timestamp.fromDate(paidAt);
    }

    await _firestore.collection('facturas').doc(invoiceId).update(updates);
  }

  @override
  Future<void> savePayment(Payment payment) async {
    await _firestore.collection('pagos').doc(payment.id).set(payment.toMap());
  }

  @override
  Future<List<Payment>> getPaymentsByInvoice(
    String invoiceId,
    String companyId,
  ) async {
    final snapshot = await _firestore
        .collection('pagos')
        .where('empresa_id', isEqualTo: companyId)
        .where('factura_id', isEqualTo: invoiceId)
        .orderBy('fecha_creacion', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<Payment>> getPaymentsByClient(
    String clientId,
    String companyId,
  ) async {
    final snapshot = await _firestore
        .collection('pagos')
        .where('empresa_id', isEqualTo: companyId)
        .where('cliente_id', isEqualTo: clientId)
        .orderBy('fecha_creacion', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    final doc = await _firestore.collection('facturas').doc(invoiceId).get();
    if (doc.exists) {
      return InvoiceModel.fromFirestore(doc);
    }
    return null;
  }

  @override
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
  }) async {
    Query query = _firestore
        .collection('facturas')
        .where('empresa_id', isEqualTo: companyId);

    if (clientId != null && clientId.isNotEmpty) {
      query = query.where('cliente_id', isEqualTo: clientId);
    }

    if (documentType != null && documentType.isNotEmpty) {
      query = query.where('tipo_documento', isEqualTo: documentType);
    }

    if (branchId != null && branchId.isNotEmpty) {
      query = query.where('sucursal_id', isEqualTo: branchId);
    }

    if (cai != null && cai.isNotEmpty) {
      query = query.where('cai', isEqualTo: cai);
    }

    query = query.orderBy('fecha_creacion', descending: true);

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
    String? emissionPoint,
  ) async {
    Query query = _firestore
        .collection('facturacion')
        .where('empresa_id', isEqualTo: companyId)
        .where('activo', isEqualTo: true);

    if (branchId != null) {
      query = query.where('sucursal_id', isEqualTo: branchId);
    }

    if (emissionPoint != null) {
      query = query.where('punto_emision', isEqualTo: emissionPoint);
    }

    final snapshot = await query.limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return FiscalConfigModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  @override
  Future<List<FiscalConfig>> getFiscalConfigs(String companyId) async {
    final query = _firestore
        .collection('facturacion')
        .where('empresa_id', isEqualTo: companyId)
        .orderBy('fecha_limite', descending: true);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => FiscalConfigModel.fromFirestore(doc))
        .toList();
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
            establishment: config.establishment,
            emissionPoint: config.emissionPoint,
            documentType: config.documentType,
            rangeMin: config.rangeMin,
            rangeMax: config.rangeMax,
            currentSequence: config.currentSequence,
            authorizationDate: config.authorizationDate,
            deadline: config.deadline,
            email: config.email,
            phone: config.phone,
            address: config.address,
            active: config.active,
            createdBy: config.createdBy,
            createdAt: config.createdAt,
            updatedBy: config.updatedBy,
            updatedAt: config.updatedAt,
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

  @override
  Future<void> archiveFiscalConfig(FiscalConfig config) async {
    final model = config is FiscalConfigModel
        ? config
        : FiscalConfigModel(
            id: config.id,
            companyId: config.companyId,
            branchId: config.branchId,
            cai: config.cai,
            rtn: config.rtn,
            establishment: config.establishment,
            emissionPoint: config.emissionPoint,
            documentType: config.documentType,
            rangeMin: config.rangeMin,
            rangeMax: config.rangeMax,
            currentSequence: config.currentSequence,
            authorizationDate: config.authorizationDate,
            deadline: config.deadline,
            email: config.email,
            phone: config.phone,
            address: config.address,
            active: false,
          );

    final data = model.toMap();
    data['archived_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('facturacion_historial').add(data);
  }

  @override
  Future<List<FiscalConfig>> getFiscalHistory(
    String companyId,
    String branchId,
  ) async {
    final query = _firestore
        .collection('facturacion_historial')
        .where('empresa_id', isEqualTo: companyId)
        .where('sucursal_id', isEqualTo: branchId)
        .orderBy('archived_at', descending: true);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => FiscalConfigModel.fromFirestore(doc))
        .toList();
  }
}
