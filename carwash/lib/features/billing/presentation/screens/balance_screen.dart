import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/balance_provider.dart';
import '../../domain/entities/invoice.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(); // Load initial data
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final companyId = authProvider.currentUser?.companyId;

    if (companyId != null) {
      await context.read<BalanceProvider>().loadInvoices(
        companyId,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      );
    }
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

    // Client-side filtering for search text (simple implementation)
    // Server-side filtering is better for scale, but this works for now.
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      invoices = invoices
          .where(
            (inv) =>
                inv.clientName.toLowerCase().contains(query) ||
                inv.invoiceNumber.toLowerCase().contains(query),
          )
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por Cliente o No. Factura',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.date_range),
                tooltip: 'Filtrar por Fecha',
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _dateRange,
                  );
                  if (picked != null) {
                    setState(() {
                      _dateRange = picked;
                    });
                    _loadData();
                  }
                },
              ),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpiar Filtro de Fecha',
                  onPressed: () {
                    setState(() => _dateRange = null);
                    _loadData();
                  },
                ),
            ],
          ),
        ),
        if (balanceProvider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (invoices.isEmpty)
          const Expanded(
            child: Center(child: Text('No hay facturas registradas.')),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
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
                    // TODO: Show Detail / Reprint PDF
                  },
                );
              },
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

    return SingleChildScrollView(
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
                  Text('Periodo: ${_dateFormatRange(_dateRange)}'),
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
    );
  }

  String _dateFormatRange(DateTimeRange? range) {
    if (range == null) return 'Todo el Historial';
    final start = DateFormat('dd/MM/yy').format(range.start);
    final end = DateFormat('dd/MM/yy').format(range.end);
    return '$start - $end';
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
