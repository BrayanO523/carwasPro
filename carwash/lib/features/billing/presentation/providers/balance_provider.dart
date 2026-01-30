import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
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
      invoices.fold(0, (acc, item) => acc + item.totalAmount);
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

  // Cache State & Pagination
  String? _lastCompanyId;
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;
  String? _lastDocumentType; // Cache Document Type
  String? _lastBranchId; // Cache Branch

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInvoices(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
    String? documentType,
    String? branchId,
    bool forceRefresh = false,
  }) async {
    // Cache check if not forced and same params
    if (!forceRefresh &&
        companyId == _lastCompanyId &&
        startDate == _lastStartDate &&
        endDate == _lastEndDate &&
        documentType == _lastDocumentType &&
        branchId == _lastBranchId &&
        _invoices.isNotEmpty) {
      return;
    }

    // Update Cache State & Reset Pagination
    _lastCompanyId = companyId;
    _lastStartDate = startDate;
    _lastEndDate = endDate;
    _lastDocumentType = documentType;
    _lastBranchId = branchId;
    _lastDocument = null;
    _hasMore = true;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final paginatedResult = await _repository.getInvoices(
        companyId,
        startDate: startDate,
        endDate: endDate,
        documentType: documentType,
        branchId: branchId,
        limit: 20,
      );

      _invoices = List<Invoice>.from(paginatedResult.items);
      _lastDocument = paginatedResult.lastDocument;

      // If we got fewer items than limit, no more pages
      if (paginatedResult.items.length < 20) {
        _hasMore = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMoreInvoices() async {
    if (_isLoadingMore ||
        !_hasMore ||
        _lastCompanyId == null ||
        _lastDocument == null) {
      return;
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      final paginatedResult = await _repository.getInvoices(
        _lastCompanyId!,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
        documentType: _lastDocumentType,
        branchId: _lastBranchId,
        limit: 20,
        startAfter: _lastDocument,
      );

      if (paginatedResult.items.isEmpty) {
        _hasMore = false;
      } else {
        _invoices.addAll(paginatedResult.items);
        _lastDocument = paginatedResult.lastDocument;
        if (paginatedResult.items.length < 20) {
          _hasMore = false;
        }
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      // Fail silently for load more, or show snackbar in UI
      log('Error loading more invoices: $e');
      notifyListeners();
    }
  }
}
