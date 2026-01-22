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
    super.clientRtn,
    required super.totalAmount,
    required super.subtotal,
    super.discountTotal,
    super.exemptAmount,
    super.taxableAmount15,
    super.taxableAmount18,
    super.isv15,
    super.isv18,
    required super.items,
    required super.createdAt,
    required super.invoiceNumber,
    required super.documentType,
  });

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: doc.id,
      companyId: data['empresa_id'] ?? '',
      branchId: data['sucursal_id'] ?? '',
      clientId: data['cliente_id'] ?? '',
      vehicleId: data['vehiculo_id'] ?? '',
      clientName: data['cliente_nombre'] ?? '',
      clientRtn: data['cliente_rtn'],
      totalAmount: (data['total'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discountTotal: (data['total_descuento'] ?? 0).toDouble(),
      exemptAmount: (data['importe_exento'] ?? 0).toDouble(),
      taxableAmount15: (data['importe_gravado_15'] ?? 0).toDouble(),
      taxableAmount18: (data['importe_gravado_18'] ?? 0).toDouble(),
      isv15: (data['isv_15'] ?? 0).toDouble(),
      isv18: (data['isv_18'] ?? 0).toDouble(),
      items: (data['items'] as List<dynamic>? ?? []).map((item) {
        return InvoiceItem(
          description: item['descripcion'] ?? '',
          quantity: (item['cantidad'] ?? 1).toDouble(),
          unitPrice: (item['precio_unitario'] ?? 0).toDouble(),
          discount: (item['descuento'] ?? 0).toDouble(),
          taxType: item['tipo_impuesto'] ?? '15',
        );
      }).toList(),
      createdAt: (data['fecha_creacion'] as Timestamp).toDate(),
      invoiceNumber: data['numero_factura'] ?? '',
      documentType: data['tipo_documento'] ?? 'invoice',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'empresa_id': companyId,
      'sucursal_id': branchId,
      'cliente_id': clientId,
      'vehiculo_id': vehicleId,
      'cliente_nombre': clientName,
      'cliente_rtn': clientRtn,
      'total': totalAmount,
      'subtotal': subtotal,
      'total_descuento': discountTotal,
      'importe_exento': exemptAmount,
      'importe_gravado_15': taxableAmount15,
      'importe_gravado_18': taxableAmount18,
      'isv_15': isv15,
      'isv_18': isv18,
      'items': items
          .map(
            (item) => {
              'descripcion': item.description,
              'cantidad': item.quantity,
              'precio_unitario': item.unitPrice,
              'descuento': item.discount,
              'tipo_impuesto': item.taxType,
              'total_linea': item.total,
            },
          )
          .toList(),
      'fecha_creacion': Timestamp.fromDate(createdAt),
      'numero_factura': invoiceNumber,
      'tipo_documento': documentType,
    };
  }
}
