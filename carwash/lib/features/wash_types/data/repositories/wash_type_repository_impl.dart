import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wash_type_model.dart';
import '../../domain/entities/wash_type.dart';
import '../../domain/repositories/wash_type_repository.dart';

class WashTypeRepositoryImpl implements WashTypeRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'tiposLavados',
  );

  @override
  Future<List<WashType>> getWashTypes({String? companyId}) async {
    // 1. Fetch Global (no companyId)
    final globalSnapshot = await _collection
        .where('empresa_id', isNull: true)
        .get();

    List<WashType> allTypes = globalSnapshot.docs
        .map((doc) => WashTypeModel.fromFirestore(doc))
        .toList();

    // 2. Fetch Company Specific (if provided)
    if (companyId != null && companyId.isNotEmpty) {
      final companySnapshot = await _collection
          .where('empresa_id', isEqualTo: companyId)
          .get();

      final companyTypes = companySnapshot.docs
          .map((doc) => WashTypeModel.fromFirestore(doc))
          .toList();

      allTypes.addAll(companyTypes);
    }

    return allTypes;
  }

  @override
  Stream<List<WashType>> getWashTypesStream({String? companyId}) {
    // Use Filter.or to get both Global (null) and Company Specific items
    // Note: Firestore 'OR' queries allow this efficiently.

    Query query = _collection;

    if (companyId != null && companyId.isNotEmpty) {
      query = query.where(
        Filter.or(
          Filter('empresa_id', isNull: true),
          Filter('empresa_id', isEqualTo: companyId),
        ),
      );
    } else {
      // Only Global
      query = query.where('empresa_id', isNull: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WashTypeModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> saveWashType(WashType washType) async {
    final model = washType as WashTypeModel;
    if (washType.id.isEmpty) {
      await _collection.add(model.toMap());
    } else {
      await _collection.doc(washType.id).set(model.toMap());
    }
  }

  @override
  Future<void> updateWashType(WashType washType) async {
    final model = washType as WashTypeModel;
    await _collection.doc(washType.id).update(model.toMap());
  }

  @override
  Future<void> deleteWashType(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<void> seedDefaultWashTypes(String companyId, String branchId) async {
    final batch = FirebaseFirestore.instance.batch();

    final List<Map<String, dynamic>> defaults = [
      // SERVICIOS BASE
      {
        "nombre": "Lavado Sencillo",
        "descripcion": "Lavado exterior básico: jabón, enjuague y secado.",
        "categoria": "base",
        "precios": {
          "moto": 100,
          "turismo": 150,
          "camioneta": 220,
          "grande": 280,
        },
        "activo": true,
        "empresa_id": companyId,
        "sucursal_ids": [branchId],
      },
      {
        "nombre": "Lavado Completo",
        "descripcion":
            "Lavado exterior, aspirado profundo, limpieza de tablero y almorol.",
        "categoria": "base",
        "precios": {
          "moto": 180,
          "turismo": 280,
          "camioneta": 350,
          "grande": 450,
        },
        "activo": true,
        "empresa_id": companyId,
        "sucursal_ids": [branchId],
      },
      // SERVICIOS EXTRA
      {
        "nombre": "Lavado de Motor",
        "descripcion": "Limpieza y desengrasado del motor.",
        "categoria": "extra",
        "precios": {
          "moto": 150,
          "turismo": 250,
          "camioneta": 250,
          "grande": 300,
        },
        "activo": true,
        "empresa_id": companyId,
        "sucursal_ids": [branchId],
      },
      {
        "nombre": "Lavado de Chasis",
        "descripcion": "Lavado a presión de la parte inferior.",
        "categoria": "extra",
        "precios": {
          "moto": 100,
          "turismo": 200,
          "camioneta": 200,
          "grande": 250,
        },
        "activo": true,
        "empresa_id": companyId,
        "sucursal_ids": [branchId],
      },
      {
        "nombre": "Pasteado (Encerado)",
        "descripcion": "Aplicación de cera protectora.",
        "categoria": "extra",
        "precios": {
          "moto": 150,
          "turismo": 300,
          "camioneta": 400,
          "grande": 500,
        },
        "activo": true,
        "empresa_id": companyId,
        "sucursal_ids": [branchId],
      },
      {
        "nombre": "Lavado de Tapicería",
        "descripcion": "Limpieza profunda de asientos y alfombras.",
        "categoria": "extra",
        "precios": {
          "moto": 300,
          "turismo": 800,
          "camioneta": 1000,
          "grande": 1200,
        },
        "activo": true,
        "empresa_id": companyId,
        "sucursal_ids": [branchId],
      },
    ];

    for (final service in defaults) {
      final doc = _collection.doc();
      batch.set(doc, service);
    }

    await batch.commit();
  }
}
