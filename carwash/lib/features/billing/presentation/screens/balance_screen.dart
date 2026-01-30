import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/balance_provider.dart';
import '../../domain/entities/invoice.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../../branch/domain/entities/branch.dart';

import '../widgets/balance_filter_sheet.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  final ScrollController _scrollController = ScrollController();
  String? _documentTypeFilter; // Document Type Filter ('invoice' or 'receipt')
  String? _branchFilter; // Branch Filter

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BalanceProvider>().loadMoreInvoices();
    }
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final companyId = authProvider.currentUser?.companyId;

    if (companyId != null) {
      await context.read<BalanceProvider>().loadInvoices(
        companyId,
        startDate: _startDate,
        endDate: _endDate,
        documentType: _documentTypeFilter,
        branchId: _branchFilter,
      );
    }
  }

  void _showFilterDialog() {
    final authProvider = context.read<AuthProvider>();
    final companyId = authProvider.currentUser?.companyId;

    if (companyId != null) {
      context.read<BranchProvider>().loadBranches(companyId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer2<BranchProvider, BalanceProvider>(
        builder: (context, branchPrv, balancePrv, _) {
          return BalanceFilterSheet(
            currentDateStart: _startDate,
            currentDateEnd: _endDate,
            currentBranchId: _branchFilter,
            currentDocumentType: _documentTypeFilter,
            branches: branchPrv.branches,
            onApply: (start, end, branchId, documentType) {
              setState(() {
                _startDate = start;
                _endDate = end;
                _branchFilter = branchId;
                _documentTypeFilter = documentType;
              });
              _loadData();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance y Facturación'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Historial', icon: Icon(Icons.history)),
            Tab(text: 'Balance', icon: Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHistoryTab(), _buildBalanceTab()],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final balanceProvider = context.watch<BalanceProvider>();
    List<Invoice> invoices = balanceProvider.invoices;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por Cliente o No. Factura',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        context.read<BalanceProvider>().setSearchText(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter Button
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.blueGrey),
                    tooltip: 'Filtros Avanzados',
                    onPressed: _showFilterDialog,
                  ),
                  if (_startDate != null ||
                      _endDate != null ||
                      _documentTypeFilter != null ||
                      _branchFilter != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Limpiar Filtros',
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _documentTypeFilter = null;
                          _branchFilter = null;
                        });
                        _loadData();
                      },
                    ),
                ],
              ),
              // Filter Chips
              if (_startDate != null ||
                  _endDate != null ||
                  _documentTypeFilter != null ||
                  _branchFilter != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      if (_startDate != null || _endDate != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              '${_startDate != null ? DateFormat('dd/MM').format(_startDate!) : '...'} - ${_endDate != null ? DateFormat('dd/MM').format(_endDate!) : '...'}',
                            ),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        ),
                      if (_documentTypeFilter != null)
                        Chip(
                          label: Text(
                            _documentTypeFilter == 'invoice'
                                ? 'Facturación'
                                : 'Recibos',
                          ),
                          backgroundColor: Colors.orange.shade50,
                        ),
                      if (_branchFilter != null)
                        Chip(
                          label: const Text('Sucursal: Filtrada'),
                          backgroundColor: Colors.purple.shade50,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (balanceProvider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadData();
              },
              child: invoices.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const Center(
                            child: Text('No hay facturas registradas.'),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          invoices.length +
                          (balanceProvider.isLoadingMore ? 1 : 0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (index == invoices.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final invoice = invoices[index];
                        return ListTile(
                          leading: Icon(
                            invoice.documentType == 'invoice'
                                ? Icons.receipt_long
                                : Icons.receipt,
                            color: invoice.documentType == 'invoice'
                                ? Colors.blue
                                : Colors.orange,
                          ),
                          title: Text(
                            invoice.clientName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${invoice.documentType == 'invoice' ? 'FAC' : 'REC'} #${invoice.invoiceNumber} • ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt)}',
                          ),
                          trailing: Text(
                            'L. ${invoice.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 15,
                            ),
                          ),
                          onTap: () {
                            _showInvoiceDetailDialog(invoice);
                          },
                        );
                      },
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceTab() {
    final balanceProvider = context.watch<BalanceProvider>();

    // Recalculate based on filtered list (invoices getter holds filtered repository state?)
    // Actually provider holds all fetched by date range.
    final totalIncome = balanceProvider.invoices.fold(
      0.0,
      (sum, item) => sum + item.totalAmount,
    );
    final totalInvoices = balanceProvider.invoices.length;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'INGRESOS TOTALES',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L. ${totalIncome.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Periodo: ${_dateFormatRange(_startDate, _endDate)}'),
                    if (_branchFilter != null ||
                        _documentTypeFilter != null) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final List<String> filters = [];
                          if (_branchFilter != null) {
                            // Try to find branch name
                            final branches = context
                                .read<BranchProvider>()
                                .branches;
                            final branch = branches.cast<Branch>().firstWhere(
                              (b) => b.id == _branchFilter,
                              orElse: () => Branch(
                                id: '',
                                name: 'Sucursal Info',
                                companyId: '',
                                address: '',
                                phone: '',
                              ),
                            );
                            filters.add(branch.name);
                          }
                          if (_documentTypeFilter != null) {
                            filters.add(
                              _documentTypeFilter == 'invoice'
                                  ? 'Facturación (Fiscal)'
                                  : 'Recibos (Balance)',
                            );
                          }
                          return Column(
                            children: filters
                                .map(
                                  (filter) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      filter,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Facturas',
                    value: totalInvoices.toString(),
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Promedio',
                    value: totalInvoices > 0
                        ? 'L. ${(totalIncome / totalInvoices).toStringAsFixed(2)}'
                        : 'L. 0.00',
                    icon: Icons.analytics,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateFormatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Todo el Historial';
    final s = start != null ? DateFormat('dd/MM/yy').format(start) : 'Inicio';
    final e = end != null ? DateFormat('dd/MM/yy').format(end) : 'Hoy';
    return '$s - $e';
  }

  void _showInvoiceDetailDialog(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${invoice.documentType == 'invoice' ? 'FACTURA' : 'RECIBO'} #${invoice.invoiceNumber}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Cliente', invoice.clientName),
                _buildDetailRow('RTN', invoice.clientRtn ?? 'Consumidor Final'),
                _buildDetailRow(
                  'Fecha',
                  DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt),
                ),
                const Divider(),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...invoice.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.description} (x${item.quantity})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'L. ${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                _buildDetailRow(
                  'Total',
                  'L. ${invoice.totalAmount.toStringAsFixed(2)}',
                  isBold: true,
                  color: Colors.green[700],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
