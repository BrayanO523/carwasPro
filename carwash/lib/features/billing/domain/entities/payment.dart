class Payment {
  final String id;
  final String invoiceId;
  final String clientId;
  final String companyId; // Important for filtering
  final double amount;
  final String
  paymentMethod; // 'efectivo', 'transferencia', 'tarjeta', 'cheque'
  final String? reference; // Bank ref, check number
  final DateTime createdAt;
  final String createdBy; // userId
  final String? notes;

  Payment({
    required this.id,
    required this.invoiceId,
    required this.clientId,
    required this.companyId,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    required this.createdAt,
    required this.createdBy,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'factura_id': invoiceId,
      'cliente_id': clientId,
      'empresa_id': companyId,
      'monto': amount,
      'metodo_pago': paymentMethod,
      'referencia': reference,
      'fecha_creacion': createdAt.toIso8601String(),
      'creado_por': createdBy,
      'notas': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      invoiceId: map['factura_id'] ?? map['invoiceId'] ?? '',
      clientId: map['cliente_id'] ?? map['clientId'] ?? '',
      companyId: map['empresa_id'] ?? map['companyId'] ?? '',
      amount: (map['monto'] ?? map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['metodo_pago'] ?? map['paymentMethod'] ?? 'efectivo',
      reference: map['referencia'] ?? map['reference'],
      createdAt: map['fecha_creacion'] != null
          ? DateTime.tryParse(map['fecha_creacion']) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['creado_por'] ?? map['createdBy'] ?? '',
      notes: map['notas'] ?? map['notes'],
    );
  }
}
