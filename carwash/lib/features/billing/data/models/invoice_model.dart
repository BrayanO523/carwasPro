import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';

class InvoiceModel extends Invoice {
  InvoiceModel({
    required super.id,
    required super.companyId,
    required super.branchId,
    required super.clientId,
    required super.vehicleId,
    required super.clientName,
    required super.clientRtn,
    required super.invoiceNumber,
    required super.items,
    required super.subtotal,
    required super.discountTotal,
    required super.exemptAmount,
    required super.taxableAmount15,
    required super.taxableAmount18,
    required super.isv15,
    required super.isv18,
    required super.totalAmount,
    required super.createdAt,
    required super.documentType,
    super.cai,
    super.caiDeadline,
    super.rangeMin,
    super.rangeMax,
    super.sequenceNumber,

    // Credit Fields
    super.paymentCondition,
    super.paymentStatus,
    super.dueDate,
    super.paidAmount,
    super.paidAt,
    super.createdBy,
    super.updatedBy,
    super.updatedAt,
  });

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: doc.id,
      companyId: data['empresa_id'] ?? data['companyId'] ?? '',
      branchId: data['sucursal_id'] ?? data['branchId'] ?? '',
      clientId: data['cliente_id'] ?? data['clientId'] ?? '',
      vehicleId: data['vehiculo_id'] ?? data['vehicleId'] ?? '',
      clientName: data['cliente_nombre'] ?? data['clientName'] ?? '',
      clientRtn: data['cliente_rtn'] ?? data['clientRtn'] ?? '',
      invoiceNumber: data['numero_factura'] ?? data['invoiceNumber'] ?? '',

      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
          .toList(),

      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      discountTotal: (data['descuento_total'] ?? 0.0).toDouble(),
      exemptAmount: (data['monto_exento'] ?? 0.0).toDouble(),
      taxableAmount15: (data['gravado_15'] ?? 0.0).toDouble(),
      taxableAmount18: (data['gravado_18'] ?? 0.0).toDouble(),
      isv15: (data['isv_15'] ?? 0.0).toDouble(),
      isv18: (data['isv_18'] ?? 0.0).toDouble(),
      totalAmount: (data['total'] ?? 0.0).toDouble(),

      createdAt: (data['fecha_creacion'] as Timestamp).toDate(),
      documentType: data['tipo_documento'] ?? 'invoice',

      cai: data['cai'],
      caiDeadline: data['fecha_limite_cai'] != null
          ? (data['fecha_limite_cai'] as Timestamp).toDate()
          : null,
      rangeMin: data['rango_min'],
      rangeMax: data['rango_max'],
      sequenceNumber: data['numero_secuencia'],

      // Credit Fields
      paymentCondition: data['condicion_pago'] ?? 'contado',
      paymentStatus: data['estado_pago'] ?? 'pagado',
      dueDate: data['fecha_vencimiento'] != null
          ? (data['fecha_vencimiento'] as Timestamp).toDate()
          : null,
      paidAmount: (data['monto_pagado'] ?? 0.0).toDouble(),
      paidAt: data['fecha_pagado'] != null
          ? (data['fecha_pagado'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'empresa_id': companyId,
      'sucursal_id': branchId,
      'cliente_id': clientId,
      'vehiculo_id': vehicleId,
      'cliente_nombre': clientName,
      'cliente_rtn': clientRtn,
      'numero_factura': invoiceNumber,

      'items': items.map((x) => x.toMap()).toList(),

      'subtotal': subtotal,
      'descuento_total': discountTotal,
      'monto_exento': exemptAmount,
      'gravado_15': taxableAmount15,
      'gravado_18': taxableAmount18,
      'isv_15': isv15,
      'isv_18': isv18,
      'total': totalAmount,

      'fecha_creacion': Timestamp.fromDate(createdAt),
      'tipo_documento': documentType,

      'cai': cai,
      'fecha_limite_cai': caiDeadline != null
          ? Timestamp.fromDate(caiDeadline!)
          : null,
      'rango_min': rangeMin,
      'rango_max': rangeMax,
      'numero_secuencia': sequenceNumber,

      // Credit
      'condicion_pago': paymentCondition,
      'estado_pago': paymentStatus,
      'fecha_vencimiento': dueDate != null
          ? Timestamp.fromDate(dueDate!)
          : null,
      'monto_pagado': paidAmount,
      'fecha_pagado': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
