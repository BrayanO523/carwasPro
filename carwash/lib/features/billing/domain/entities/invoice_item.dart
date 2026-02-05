class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double total;
  final String taxType; // 'E' (Exempt), '15' (15%), '18' (18%)

  InvoiceItem({
    required this.description,
    this.quantity = 1.0,
    required this.unitPrice,
    this.discount = 0.0,
    this.taxType = '15',
  }) : total = (unitPrice * quantity) - discount;

  // Compatibility getter for existing code
  double get price => total;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'total': total,
      'taxType': taxType,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 1.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      taxType: map['taxType'] ?? '15',
    );
  }
}
