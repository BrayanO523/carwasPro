import 'package:flutter/material.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/balance_repository.dart';

class BalanceProvider extends ChangeNotifier {
  final BalanceRepository _repository;

  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;

  BalanceProvider({required BalanceRepository repository})
    : _repository = repository;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Balance Getters
  double get totalIncome =>
      _invoices.fold(0, (sum, item) => sum + item.totalAmount);
  int get totalInvoices => _invoices.length;

  Future<void> createInvoice(Invoice invoice) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.saveInvoice(invoice);
      _invoices.insert(0, invoice); // Optimistic update
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Cache State
  String? _lastCompanyId;
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;

  Future<void> loadInvoices(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    // Cache check
    if (!forceRefresh &&
        companyId == _lastCompanyId &&
        startDate == _lastStartDate &&
        endDate == _lastEndDate &&
        _invoices.isNotEmpty) {
      return;
    }

    // Update Cache State
    _lastCompanyId = companyId;
    _lastStartDate = startDate;
    _lastEndDate = endDate;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final invoicesResponse = await _repository.getInvoices(
        companyId,
        startDate: startDate,
        endDate: endDate,
      );
      _invoices = List<Invoice>.from(invoicesResponse);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
