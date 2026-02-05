import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/balance_provider.dart';
import '../../domain/entities/invoice.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../../branch/domain/entities/branch.dart';
import 'package:carwash/core/utils/export_service.dart';

import '../widgets/balance_filter_sheet.dart';
import '../widgets/revenue_chart.dart';

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

    // Set default filter to current user's branch
    final user = context.read<AuthProvider>().currentUser;
    if (user?.branchId != null) {
      _branchFilter = user?.branchId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<BranchProvider>().loadBranches(user.companyId);
      }
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
                  IconButton(
                    icon: const Icon(Icons.file_download),
                    tooltip: 'Exportar Reporte',
                    onPressed: () async {
                      if (invoices.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No hay datos para exportar'),
                          ),
                        );
                        return;
                      }
                      await ExportService().exportInvoicesToPdf(
                        invoices,
                        title: 'Reporte de Balance',
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                    },
                  ),
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

    // 1. Calculate Aggregates
    final totalIncome = balanceProvider.invoices.fold(
      0.0,
      (sum, item) => sum + item.totalAmount,
    );
    final totalInvoices = balanceProvider.invoices.length;

    // 2. Prepare Data for Chart
    final Map<DateTime, double> dailyRevenue = {};
    for (var invoice in balanceProvider.invoices) {
      final date = DateTime(
        invoice.createdAt.year,
        invoice.createdAt.month,
        invoice.createdAt.day,
      );
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + invoice.totalAmount;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PREMIUM TOTAL CARD
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF334155),
                  ], // Slate 900 -> 700
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative Glow
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ingresos Totales',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.blueGrey[100],
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Flexible(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 150,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _showFilterModal,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _branchFilter != null
                                                ? Icons.store
                                                : Icons.filter_list,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _branchFilter != null
                                                  ? _getBranchName(
                                                      _branchFilter!,
                                                    )
                                                  : (_startDate == null
                                                        ? 'Filtrar'
                                                        : _dateFormatRange(
                                                            _startDate,
                                                            _endDate,
                                                          )),
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 14,
                                            color: Colors.white54,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'L. ${NumberFormat("#,##0.00", "en_US").format(totalIncome)}',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        if (_branchFilter != null ||
                            _documentTypeFilter != null) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          // Premium Filter Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _buildPremiumFilterTags(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SECTION TITLE
            Text(
              'Métricas Clave',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 16),

            // METRICS GRID
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Facturas',
                    value: totalInvoices.toString(),
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF3B82F6), // Blue 500
                    trend: '+0%', // Placeholder for future logic
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Promedio por Factura',
                    value: totalInvoices > 0
                        ? 'L. ${(totalIncome / totalInvoices).toStringAsFixed(0)}'
                        : 'L. 0',
                    icon: Icons.show_chart_rounded,
                    color: const Color(0xFF10B981), // Emerald 500
                    trend: 'Estable',
                    trendUp: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // CHART SECTION
            Text(
              'Comportamiento Diario',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 16),

            RevenueChart(invoices: balanceProvider.invoices),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPremiumFilterTags() {
    final List<Widget> tags = [];
    if (_branchFilter != null) {
      final branches = context.read<BranchProvider>().branches;
      final branch = branches.cast<Branch>().firstWhere(
        (b) => b.id == _branchFilter,
        orElse: () => Branch(
          id: '',
          name: 'Sucursal',
          companyId: '',
          address: '',
          phone: '',
        ),
      );
      tags.add(_buildTag('Sucursal: ${branch.name}', Icons.store));
    }
    if (_documentTypeFilter != null) {
      tags.add(
        _buildTag(
          _documentTypeFilter == 'invoice' ? 'Facturación Fiscal' : 'Recibos',
          Icons.description,
        ),
      );
    }
    return tags;
  }

  Widget _buildTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
                _buildDetailRow('RTN', invoice.clientRtn),
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

  String _getBranchName(String branchId) {
    try {
      final branches = context.read<BranchProvider>().branches;
      final branch = branches.cast<Branch>().firstWhere(
        (b) => b.id == branchId,
      );
      return branch.name;
    } catch (e) {
      return 'Sucursal';
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final branches = context.read<BranchProvider>().branches;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filtrar Balance',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Section: SUCURSALES
                  Text(
                    'Sucursal',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120, // Limit height for list
                    child: ListView(
                      children: [
                        _buildFilterOption(
                          label: 'Todas las Sucursales',
                          isSelected: _branchFilter == null,
                          onTap: () {
                            setState(() => _branchFilter = null);
                            Navigator.pop(context);
                            _loadData();
                          },
                        ),
                        ...branches.map(
                          (branch) => _buildFilterOption(
                            label: branch.name,
                            isSelected: _branchFilter == branch.id,
                            onTap: () {
                              setState(() => _branchFilter = branch.id);
                              Navigator.pop(context);
                              _loadData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),

                  // Section: RANGO DE FECHAS (Preserve existing functionality)
                  Text(
                    'Periodo de Tiempo',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickDateRange();
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_dateFormatRange(_startDate, _endDate)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_startDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                            Navigator.pop(context);
                            _loadData();
                          },
                          icon: const Icon(Icons.clear, color: Colors.red),
                          tooltip: 'Borrar Fechas',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendUp;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = '', // Default empty if no trend logic yet
    this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendUp ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trend,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: trendUp
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.blueGrey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
        ],
      ),
    );
  }
}
