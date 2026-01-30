class Client {
  final String id;
  final String fullName;
  final String phone;
  final String? rtn;
  final String? address;
  final String? email;
  final String companyId;
  final String? branchId;

  Client({
    required this.id,
    required this.fullName,
    required this.phone,
    this.rtn,
    this.address,
    this.email,
    required this.companyId,
    this.branchId,
  });
}
