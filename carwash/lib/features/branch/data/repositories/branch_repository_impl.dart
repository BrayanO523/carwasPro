import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';
import '../models/branch_model.dart';

class BranchRepositoryImpl implements BranchRepository {
  final FirebaseFirestore _firestore;

  BranchRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createBranch(Branch branch) async {
    await _firestore
        .collection('sucursales')
        .doc(branch.id)
        .set((branch as BranchModel).toMap());
  }

  @override
  Future<List<Branch>> getBranches(String companyId) async {
    final snapshot = await _firestore
        .collection('sucursales')
        .where('empresa_id', isEqualTo: companyId)
        .get();

    return snapshot.docs.map((doc) => BranchModel.fromFirestore(doc)).toList();
  }

  @override
  Future<Branch?> getBranch(String branchId) async {
    final doc = await _firestore.collection('sucursales').doc(branchId).get();
    if (doc.exists) {
      return BranchModel.fromFirestore(doc);
    }
    return null;
  }

  @override
  Future<void> updateBranch(Branch branch) async {
    await _firestore
        .collection('sucursales')
        .doc(branch.id)
        .update((branch as BranchModel).toMap());
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    await _firestore.collection('sucursales').doc(branchId).delete();
  }
}
