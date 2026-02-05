class Branch {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String companyId;
  final String establishmentNumber;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.companyId,
    this.establishmentNumber = '000', // Default
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
}
