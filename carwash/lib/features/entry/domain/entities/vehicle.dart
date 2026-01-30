class Vehicle {
  final String id;
  // Removed model
  final String clientId;
  final String companyId;
  final DateTime entryDate;
  final List<String> photoUrls;
  final String status; // 'pending', 'washing', 'finished'

  final String clientName;
  final String? plate;
  final String? brand;
  final String? color;
  final String? branchId;
  final String? vehicleType; // moto, turismo, camioneta, grande
  final List<String> services;

  static const String statusWashing = 'washing';
  static const String statusWashed = 'washed';
  static const String statusFinished = 'finished';

  static const List<String> types = [
    'moto',
    'trimoto',
    'turismo',
    'camioneta',
    'pick_up',
    'microbus',
    'camion',
    'autobus',
    'cabezal',
    'otro',
  ];

  Vehicle({
    required this.id,
    // required this.model, // Removed
    required this.clientId,
    required this.companyId,
    required this.entryDate,
    required this.photoUrls,
    required this.status,
    required this.clientName,
    this.plate,
    this.brand,
    this.color,
    this.branchId,
    this.vehicleType,
    this.services = const [],
  });
}
