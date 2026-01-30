import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/fiscal_config.dart';

class FiscalConfigModel extends FiscalConfig {
  FiscalConfigModel({
    required super.id,
    required super.companyId,
    super.branchId,
    required super.cai,
    required super.rtn,
    required super.establishment,
    required super.emissionPoint,
    required super.documentType,
    required super.rangeMin,
    required super.rangeMax,
    required super.currentSequence,
    required super.authorizationDate,
    required super.deadline,
    required super.email,
    required super.phone,
    required super.address,
    super.active,
  });

  factory FiscalConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FiscalConfigModel(
      id: doc.id,
      companyId: data['empresa_id'] ?? '',
      branchId: data['sucursal_id'],
      cai: data['cai'],
      rtn: data['rtn'],
      establishment: data['establecimiento'],
      emissionPoint: data['punto_emision'],
      documentType: data['tipo_documento'],
      rangeMin: int.tryParse(data['rango_min'].toString()),
      rangeMax: int.tryParse(data['rango_max'].toString()),
      currentSequence: int.tryParse(data['secuencia_actual'].toString()) ?? 0,
      authorizationDate: (data['fecha_autorizacion'] as Timestamp?)?.toDate(),
      deadline: (data['fecha_limite'] as Timestamp?)?.toDate(),
      email: data['correo'] ?? '',
      phone: data['telefono'] ?? '',
      address: data['direccion'] ?? '',
      active: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'empresa_id': companyId,
      'sucursal_id': branchId,
      'cai': cai,
      'rtn': rtn,
      'establecimiento': establishment,
      'punto_emision': emissionPoint,
      'tipo_documento': documentType,
      'rango_min': rangeMin,
      'rango_max': rangeMax,
      'secuencia_actual': currentSequence,
      'fecha_autorizacion': authorizationDate != null
          ? Timestamp.fromDate(authorizationDate!)
          : null,
      'fecha_limite': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'correo': email,
      'telefono': phone,
      'direccion': address,
      'activo': active,
    };
  }
}
