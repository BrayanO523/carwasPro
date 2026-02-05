import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wash_type_model.dart';
import '../../domain/entities/wash_type.dart';
import '../../domain/repositories/wash_type_repository.dart';

class WashTypeRepositoryImpl implements WashTypeRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'tiposLavados',
  );

  @override
  Future<List<WashType>> getWashTypes({
    String? companyId,
    String? branchId,
  }) async {
    // 1. Fetch Global (no companyId)
    // Global types are usually available to everyone, unless we want to restrict them too.
    // For now, assuming Global = All Branches.
    final globalSnapshot = await _collection
        .where('empresa_id', isNull: true)
        .get();

    List<WashType> allTypes = globalSnapshot.docs
        .map((doc) => WashTypeModel.fromFirestore(doc))
        .toList();

    // 2. Fetch Company Specific (if provided)
    if (companyId != null && companyId.isNotEmpty) {
      Query companyQuery = _collection.where(
        'empresa_id',
        isEqualTo: companyId,
      );

      if (branchId != null && branchId.isNotEmpty) {
        companyQuery = companyQuery.where(
          'sucursal_ids',
          arrayContains: branchId,
        );
      }

      final companySnapshot = await companyQuery.get();

      final companyTypes = companySnapshot.docs
          .map((doc) => WashTypeModel.fromFirestore(doc))
          .toList();

      allTypes.addAll(companyTypes);
    }

    return allTypes;
  }

  @override
  Stream<List<WashType>> getWashTypesStream({
    String? companyId,
    String? branchId,
  }) {
    // Note: 'OR' queries with array-contains can be complex or unsupported in some SDK versions/indexes.
    // If branchId is provided, we specifically want types available to THAT branch.
    // Global types (empresa_id == null) are implicitly available.

    // Strategy:
    // If branchId is present, we filter strictly for that branch within the company scope.
    // Merging streams or client-side filtering might be necessary if we want Global + Branch Specific in one go
    // without complex indexes.
    // However, let's try to keep it simple. If Company ID is present:

    Query query = _collection;

    if (companyId != null && companyId.isNotEmpty) {
      // Basic Company Filter
      query = query.where('empresa_id', isEqualTo: companyId);

      if (branchId != null && branchId.isNotEmpty) {
        query = query.where('sucursal_ids', arrayContains: branchId);
      }
    } else {
      // Only Global
      query = query.where('empresa_id', isNull: true);
    }

    // Note: This implementation SEPARATES Global and Company.
    // If the user needs BOTH (Global defaults + Company/Branch Specific),
    // we normally need two queries.
    // PREVIOUS IMPLEMENTATION merged them in `getWashTypes` but used `Filter.or` for stream.
    // `Filter.or` with `array-contains` might require composite index.

    // REVISED STRATEGY FOR STREAM:
    // To safe-guard against index issues, we'll listen to the Company+Branch stream
    // AND the Global stream if needed, or simply stick to the Company stream if overrides are expected.
    // Given the previous code used `Filter.or`, let's try to maintain that BUT apply branch filter
    // ONLY to the company part... which is hard in a single query.

    // Allow simplified stream: Just return Company+Branch specific items.
    // Global items (defaults) should generally be copied/seeded into the company/branch
    // if modification is needed, OR we accept that this stream only returns the custom ones.

    // ACTUALLY, checking previous code:
    // It used `Filter.or(Filter('empresa_id', isNull: true), Filter('empresa_id', isEqualTo: companyId))`

    // If we add branchId check, it complicates the Global part (which has no branchId usually).
    // Let's rely on CLIENT-SIDE merging/filtering for the stream to ensure robustness without index explosion.
    // We fetch ALL company types, then filter by branchId in Dart.

    Query streamQuery = _collection;
    if (companyId != null) {
      streamQuery = streamQuery.where('empresa_id', isEqualTo: companyId);
    }

    return streamQuery.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => WashTypeModel.fromFirestore(doc)).where((
        type,
      ) {
        // Client-side strict filtering

        // 1. If Company-specific, it MUST have the branchId if we are filtering by it
        // Note: We already filtered by companyId in the query
        if (branchId != null) {
          return type.branchIds.contains(branchId);
        }

        // 2. If no branch filter provided, return all company types
        return true;
      }).toList();
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
