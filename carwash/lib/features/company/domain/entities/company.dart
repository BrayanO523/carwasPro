class Company {
  final String id;
  final String name;
  final String rtn; // Tax ID in Honduras (RTN) or generic
  final String address;
  final String phone;
  final String email;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.rtn,
    required this.address,
    required this.phone,
    required this.email,
    required this.createdAt,
  });
}
