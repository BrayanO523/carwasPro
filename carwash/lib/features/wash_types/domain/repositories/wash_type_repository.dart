import '../entities/wash_type.dart';

abstract class WashTypeRepository {
  Future<List<WashType>> getWashTypes({String? companyId});
  Stream<List<WashType>> getWashTypesStream({String? companyId});
  Future<void> saveWashType(WashType washType);
  Future<void> updateWashType(WashType washType);
  Future<void> deleteWashType(String id);
}
