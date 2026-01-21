class Client {
  final String id;
  final String name;
  final String lastName;
  final String phone;
  final String? rtn;
  final String? address;
  final String? email;
  final String companyId;

  Client({
    required this.id,
    required this.name,
    required this.lastName,
    required this.phone,
    this.rtn,
    this.address,
    this.email,
    required this.companyId,
  });
}
