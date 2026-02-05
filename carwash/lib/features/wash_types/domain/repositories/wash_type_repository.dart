import '../entities/wash_type.dart';

abstract class WashTypeRepository {
  Future<List<WashType>> getWashTypes({String? companyId, String? branchId});
  Stream<List<WashType>> getWashTypesStream({
    String? companyId,
    String? branchId,
  });
  Future<void> saveWashType(WashType washType);
  Future<void> updateWashType(WashType washType);
  Future<void> deleteWashType(String id);
  Future<void> seedDefaultWashTypes(String companyId, String branchId);
}
