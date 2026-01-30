class Product {
  final String id;
  final String companyId;
  final List<String> branchIds;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isActive;

  Product({
    required this.id,
    required this.companyId,
    required this.branchIds,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isActive = true,
  });
}
