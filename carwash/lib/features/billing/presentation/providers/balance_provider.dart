import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/invoice.dart';

import '../../domain/repositories/balance_repository.dart';

/// Chart view mode for revenue aggregation
enum ChartViewMode { daily, weekly, monthly }

/// Data class for chart points
class RevenueChartData {
  final String label;
  final double revenue;
  final int count;

  RevenueChartData(this.label, this.revenue, this.count);
}

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

  /// Generates aggregated chart data based on view mode (Daily/Weekly/Monthly)
  List<RevenueChartData> getChartData(ChartViewMode viewMode) {
    final now = DateTime.now();

    switch (viewMode) {
      case ChartViewMode.daily:
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final todayInvoices = _invoices
            .where(
              (inv) =>
                  inv.createdAt.isAfter(
                    todayStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  inv.createdAt.isBefore(todayEnd),
            )
            .toList();

        Map<int, double> hourlyData = {};
        Map<int, int> hourlyCounts = {};

        for (var inv in todayInvoices) {
          final hour = inv.createdAt.hour;
          hourlyData[hour] = (hourlyData[hour] ?? 0) + inv.totalAmount;
          hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + 1;
        }

        List<RevenueChartData> result = [];
        // Fixed Business Hours: 7am to 9pm (ensures line continuity)
        for (int h = 7; h <= 21; h++) {
          final label = h < 12 ? '${h}am' : (h == 12 ? '12pm' : '${h - 12}pm');
          result.add(
            RevenueChartData(label, hourlyData[h] ?? 0, hourlyCounts[h] ?? 0),
          );
        }
        return result;

      case ChartViewMode.weekly:
        final weekday = now.weekday;
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));

        final weekInvoices = _invoices
            .where(
              (inv) =>
                  inv.createdAt.isAfter(
                    weekStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  inv.createdAt.isBefore(weekEnd),
            )
            .toList();

        Map<int, double> dailyData = {};
        Map<int, int> dailyCounts = {};

        for (var inv in weekInvoices) {
          final day = inv.createdAt.weekday;
          dailyData[day] = (dailyData[day] ?? 0) + inv.totalAmount;
          dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
        }

        const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        List<RevenueChartData> weekResult = [];
        for (int d = 1; d <= 7; d++) {
          weekResult.add(
            RevenueChartData(
              dayNames[d - 1],
              dailyData[d] ?? 0,
              dailyCounts[d] ?? 0,
            ),
          );
        }
        return weekResult;

      case ChartViewMode.monthly:
        final monthStart = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);

        final monthInvoices = _invoices
            .where(
              (inv) =>
                  inv.createdAt.isAfter(
                    monthStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  inv.createdAt.isBefore(nextMonth),
            )
            .toList();

        Map<int, double> monthlyData = {};
        Map<int, int> monthlyCounts = {};

        for (var inv in monthInvoices) {
          final day = inv.createdAt.day;
          monthlyData[day] = (monthlyData[day] ?? 0) + inv.totalAmount;
          monthlyCounts[day] = (monthlyCounts[day] ?? 0) + 1;
        }

        List<RevenueChartData> monthResult = [];
        final maxDay = now.day;
        for (int d = 1; d <= maxDay; d++) {
          monthResult.add(
            RevenueChartData('$d', monthlyData[d] ?? 0, monthlyCounts[d] ?? 0),
          );
        }
        return monthResult;
    }
  }

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
