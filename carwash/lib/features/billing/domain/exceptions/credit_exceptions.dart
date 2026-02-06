class CreditLimitExceededException implements Exception {
  final double limit;
  final double currentBalance;
  final double saleAmount;

  CreditLimitExceededException({
    required this.limit,
    required this.currentBalance,
    required this.saleAmount,
  });

  double get exceededAmount => (currentBalance + saleAmount) - limit;

  @override
  String toString() {
    return 'Límite de crédito excedido. Balance: \${currentBalance.toStringAsFixed(2)} + Venta: \${saleAmount.toStringAsFixed(2)} > Límite: \${limit.toStringAsFixed(2)}';
  }
}
