import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/fiscal_config.dart';

class FiscalConfigModel extends FiscalConfig {
  FiscalConfigModel({
    required super.id,
    required super.companyId,
    super.branchId,
    required super.cai,
    required super.rtn,
    required super.rangeMin,
    required super.rangeMax,
    required super.currentSequence,
    required super.deadline,
    required super.email,
    required super.phone,
    required super.address,
  });

  factory FiscalConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FiscalConfigModel(
      id: doc.id,
      companyId: data['empresa_id'] ?? '',
      branchId: data['sucursal_id'],
      cai: data['cai'] ?? '',
      rtn: data['rtn'] ?? '',
      rangeMin: data['rango_min'] ?? '',
      rangeMax: data['rango_max'] ?? '',
      currentSequence: data['secuencia_actual'] ?? '',
      deadline: (data['fecha_limite'] as Timestamp).toDate(),
      email: data['correo'] ?? '',
      phone: data['telefono'] ?? '',
      address: data['direccion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'empresa_id': companyId,
      'sucursal_id': branchId,
      'cai': cai,
      'rtn': rtn,
      'rango_min': rangeMin,
      'rango_max': rangeMax,
      'secuencia_actual': currentSequence,
      'fecha_limite': Timestamp.fromDate(deadline),
      'correo': email,
      'telefono': phone,
      'direccion': address,
    };
  }
}
