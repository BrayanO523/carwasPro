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

  // Search State
  String _searchText = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Balance Getters
  double get totalIncome =>
      invoices.fold(0, (sum, item) => sum + item.totalAmount);
  int get totalInvoices => invoices.length;

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  List<Invoice> get invoices {
    if (_searchText.isEmpty) {
      return _invoices;
    }
    final query = _searchText.toLowerCase();
    return _invoices.where((inv) {
      return inv.clientName.toLowerCase().contains(query) ||
          inv.invoiceNumber.toLowerCase().contains(query);
    }).toList();
  }

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
