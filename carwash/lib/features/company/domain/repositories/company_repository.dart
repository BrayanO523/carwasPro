import '../entities/company.dart';

abstract class CompanyRepository {
  Future<void> registerCompany(Company company);
  Future<Company?> getCompany(String id);
}
