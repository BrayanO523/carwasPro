import 'package:carwash/features/billing/domain/entities/invoice_item.dart';

class Invoice {
  final String id;
  final String companyId;
  final String branchId;
  final String clientId;
  final String vehicleId;
  final String clientName;
  final String clientRtn; // Or RTN used specifically for this invoice
  final String invoiceNumber;
  final List<InvoiceItem> items;

  // Amounts
  final double subtotal;
  final double discountTotal;
  final double exemptAmount;
  final double taxableAmount15;
  final double taxableAmount18;
  final double isv15;
  final double isv18;
  final double totalAmount;

  // Metadata
  final DateTime createdAt;
  final String documentType; // 'invoice' 01, 'receipt' 11 (ticket)

  // Fiscal Data
  final String? cai;
  final DateTime? caiDeadline;
  final int? rangeMin;
  final int? rangeMax;
  final int? sequenceNumber;

  // Accounts Receivable / Payment Fields (New)
  final String paymentCondition; // 'contado' or 'credito'
  final String paymentStatus; // 'pendiente', 'parcial', 'pagado', 'vencido'
  final DateTime? dueDate; // Required if credito
  final double paidAmount; // Accumulated payments
  final DateTime? paidAt; // Date strictly fully paid

  // Audit
  final String? createdBy;
  final String? updatedBy;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.clientId,
    required this.vehicleId,
    required this.clientName,
    required this.clientRtn,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.exemptAmount,
    required this.taxableAmount15,
    required this.taxableAmount18,
    required this.isv15,
    required this.isv18,
    required this.totalAmount,
    required this.createdAt,
    required this.documentType,
    this.cai,
    this.caiDeadline,
    this.rangeMin,
    this.rangeMax,
    this.sequenceNumber,

    // Defaults for backward compatibility
    this.paymentCondition = 'contado',
    this.paymentStatus = 'pagado',
    this.dueDate,
    this.paidAmount =
        0.0, // If 'pagado' or 'contado', usually full amount, but depends on migration
    this.paidAt,
    this.createdBy,
    this.updatedBy,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'branchId': branchId,
      'clientId': clientId,
      'vehicleId': vehicleId,
      'clientName': clientName,
      'clientRtn': clientRtn,
      'invoiceNumber': invoiceNumber,
      'items': items.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'discountTotal': discountTotal,
      'exemptAmount': exemptAmount,
      'taxableAmount15': taxableAmount15,
      'taxableAmount18': taxableAmount18,
      'isv15': isv15,
      'isv18': isv18,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'documentType': documentType,
      'cai': cai,
      'caiDeadline': caiDeadline?.toIso8601String(),
      'rangeMin': rangeMin,
      'rangeMax': rangeMax,
      'sequenceNumber': sequenceNumber,
      'paymentCondition': paymentCondition,
      'paymentStatus': paymentStatus,
      'dueDate': dueDate?.toIso8601String(),
      'paidAmount': paidAmount,
      'paidAt': paidAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      companyId: map['companyId'] ?? '',
      branchId: map['branchId'] ?? '',
      clientId: map['clientId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientRtn: map['clientRtn'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      items: List<InvoiceItem>.from(
        (map['items'] as List<dynamic>? ?? []).map<InvoiceItem>(
          (x) => InvoiceItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      discountTotal: (map['discountTotal'] ?? 0.0).toDouble(),
      exemptAmount: (map['exemptAmount'] ?? 0.0).toDouble(),
      taxableAmount15: (map['taxableAmount15'] ?? 0.0).toDouble(),
      taxableAmount18: (map['taxableAmount18'] ?? 0.0).toDouble(),
      isv15: (map['isv15'] ?? 0.0).toDouble(),
      isv18: (map['isv18'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      documentType: map['documentType'] ?? '01',
      cai: map['cai'],
      caiDeadline: map['caiDeadline'] != null
          ? DateTime.parse(map['caiDeadline'])
          : null,
      rangeMin: map['rangeMin'],
      rangeMax: map['rangeMax'],
      sequenceNumber: map['sequenceNumber'],

      // New fields with safe defaults
      paymentCondition: map['paymentCondition'] ?? 'contado',
      paymentStatus:
          map['paymentStatus'] ??
          (map['paymentCondition'] == 'credito' ? 'pendiente' : 'pagado'),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      paidAmount:
          (map['paidAmount'] ??
                  (map['paymentCondition'] == 'credito'
                      ? 0.0
                      : (map['totalAmount'] ?? 0.0)))
              .toDouble(),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Invoice copyWith({
    String? id,
    String? companyId,
    String? branchId,
    String? clientId,
    String? vehicleId,
    String? clientName,
    String? clientRtn,
    String? invoiceNumber,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discountTotal,
    double? exemptAmount,
    double? taxableAmount15,
    double? taxableAmount18,
    double? isv15,
    double? isv18,
    double? totalAmount,
    DateTime? createdAt,
    String? documentType,
    String? cai,
    DateTime? caiDeadline,
    int? rangeMin,
    int? rangeMax,
    int? sequenceNumber,
    String? paymentCondition,
    String? paymentStatus,
    DateTime? dueDate,
    double? paidAmount,
    DateTime? paidAt,
    String? createdBy,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      clientId: clientId ?? this.clientId,
      vehicleId: vehicleId ?? this.vehicleId,
      clientName: clientName ?? this.clientName,
      clientRtn: clientRtn ?? this.clientRtn,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountTotal: discountTotal ?? this.discountTotal,
      exemptAmount: exemptAmount ?? this.exemptAmount,
      taxableAmount15: taxableAmount15 ?? this.taxableAmount15,
      taxableAmount18: taxableAmount18 ?? this.taxableAmount18,
      isv15: isv15 ?? this.isv15,
      isv18: isv18 ?? this.isv18,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      documentType: documentType ?? this.documentType,
      cai: cai ?? this.cai,
      caiDeadline: caiDeadline ?? this.caiDeadline,
      rangeMin: rangeMin ?? this.rangeMin,
      rangeMax: rangeMax ?? this.rangeMax,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      paymentCondition: paymentCondition ?? this.paymentCondition,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dueDate: dueDate ?? this.dueDate,
      paidAmount: paidAmount ?? this.paidAmount,
      paidAt: paidAt ?? this.paidAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
