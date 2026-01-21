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
    required super.isv,
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
      isv: (data['isv'] ?? 0).toDouble(),
      items: (data['items'] as List<dynamic>? ?? []).map((item) {
        return InvoiceItem(
          description: item['descripcion'] ?? '',
          price: (item['precio'] ?? 0).toDouble(),
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
      'isv': isv,
      'items': items
          .map(
            (item) => {'descripcion': item.description, 'precio': item.price},
          )
          .toList(),
      'fecha_creacion': Timestamp.fromDate(createdAt),
      'numero_factura': invoiceNumber,
      'tipo_documento': documentType,
    };
  }
}
