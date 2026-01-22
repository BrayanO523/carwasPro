class WashType {
  final String id;
  final String name;
  final String description;
  final String category; // 'base' or 'extra'
  final bool isActive;
  final Map<String, double> prices;
  final String? companyId; // Null for global defaults
  final List<String> branchIds; // Empty = All branches

  const WashType({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isActive,
    required this.prices,
    this.companyId,
    this.branchIds = const [],
  });

  // Price Getters helpers
  double getPriceFor(String vehicleType) => prices[vehicleType] ?? 0.0;
}
