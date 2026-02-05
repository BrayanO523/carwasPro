class FiscalConfig {
  final String id;
  final String companyId;
  final String? branchId; // Optional: Global or per-branch config
  final String? cai;
  final String? rtn;
  final String? establishment; // 000
  final String? emissionPoint; // 001
  final String? documentType; // 01
  final int? rangeMin;
  final int? rangeMax;
  final int currentSequence;
  final DateTime? authorizationDate; // Fecha de Inicio/Emisión
  final DateTime? deadline;
  final String email;
  final String phone;
  final String address;
  final bool active; // Track if this is the current active CAI

  FiscalConfig({
    required this.id,
    required this.companyId,
    this.branchId,
    this.cai,
    this.rtn,
    this.establishment,
    this.emissionPoint,
    this.documentType,
    this.rangeMin,
    this.rangeMax,
    required this.currentSequence,
    this.authorizationDate,
    this.deadline,
    required this.email,
    required this.phone,
    required this.address,
    this.active = true,
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
