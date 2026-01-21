import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../models/company_model.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final FirebaseFirestore _firestore;

  CompanyRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> registerCompany(Company company) async {
    // We use the company ID as the document ID
    await _firestore
        .collection('companies')
        .doc(company.id)
        .set((company as CompanyModel).toMap());
  }

  @override
  Future<Company?> getCompany(String id) async {
    final doc = await _firestore.collection('companies').doc(id).get();
    if (doc.exists) {
      return CompanyModel.fromFirestore(doc);
    }
    return null;
  }
}
