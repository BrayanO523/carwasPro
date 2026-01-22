class FiscalConfig {
  final String id;
  final String companyId;
  final String? branchId; // Optional: Global or per-branch config
  final String cai;
  final String rtn;
  final String rangeMin;
  final String rangeMax;
  final String currentSequence;
  final DateTime deadline;
  final String email;
  final String phone;
  final String address;

  FiscalConfig({
    required this.id,
    required this.companyId,
    this.branchId,
    required this.cai,
    required this.rtn,
    required this.rangeMin,
    required this.rangeMax,
    required this.currentSequence,
    required this.deadline,
    required this.email,
    required this.phone,
    required this.address,
  });
}
