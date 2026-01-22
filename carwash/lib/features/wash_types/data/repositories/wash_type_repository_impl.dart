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
}
