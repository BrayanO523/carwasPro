import '../entities/branch.dart';

abstract class BranchRepository {
  Future<void> createBranch(Branch branch);
  Future<List<Branch>> getBranches(String companyId);
  Future<Branch?> getBranch(String branchId);
  Future<void> updateBranch(Branch branch);
  Future<void> deleteBranch(String branchId);
}
