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
}
