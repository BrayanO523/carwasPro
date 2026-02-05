import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';
import '../models/branch_model.dart';
import 'package:carwash/features/audit/domain/entities/audit_log.dart';
import 'package:carwash/features/audit/domain/repositories/audit_repository.dart';

class BranchRepositoryImpl implements BranchRepository {
  final FirebaseFirestore _firestore;
  final AuditRepository _auditRepository;

  BranchRepositoryImpl({
    FirebaseFirestore? firestore,
    AuditRepository? auditRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditRepository =
           auditRepository ??
           (throw ArgumentError('AuditRepository cannot be null'));

  @override
  Future<void> createBranch(Branch branch) async {
    await _firestore
        .collection('sucursales')
        .doc(branch.id)
        .set((branch as BranchModel).toMap());

    await _auditRepository.logEvent(
      AuditLog(
        id: const Uuid().v4(),
        action: 'CREATE_BRANCH',
        collection: 'sucursales',
        documentId: branch.id,
        userId: branch.createdBy ?? 'unknown',
        userEmail: 'unknown',
        timestamp: DateTime.now(),
        details: branch.toMap(),
        companyId: branch.companyId,
        branchId: branch.id,
      ),
    );
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

    await _auditRepository.logEvent(
      AuditLog(
        id: const Uuid().v4(),
        action: 'UPDATE_BRANCH',
        collection: 'sucursales',
        documentId: branch.id,
        userId: branch.updatedBy ?? 'unknown',
        userEmail: 'unknown',
        timestamp: DateTime.now(),
        details: branch.toMap(),
        companyId: branch.companyId,
        branchId: branch.id,
      ),
    );
  }

  @override
  Future<void> deleteBranch(String branchId, {String? userId}) async {
    // Get branch to find companyId before deleting
    final doc = await _firestore.collection('sucursales').doc(branchId).get();
    final companyId = doc.exists ? doc.get('empresa_id') : '';

    await _firestore.collection('sucursales').doc(branchId).delete();

    await _auditRepository.logEvent(
      AuditLog(
        id: const Uuid().v4(),
        action: 'DELETE_BRANCH',
        collection: 'sucursales',
        documentId: branchId,
        userId: userId ?? 'unknown',
        userEmail: 'unknown',
        timestamp: DateTime.now(),
        details: {'deleted': true},
        companyId: companyId,
        branchId: branchId,
      ),
    );
  }
}
