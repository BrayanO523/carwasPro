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
              // Filter Buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, size: 20),
                    tooltip: 'Desde',
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateRange?.start ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          final end = _dateRange?.end ?? DateTime.now();
                          // Ensure start is before end
                          if (picked.isAfter(end)) {
                            _dateRange = DateTimeRange(
                              start: picked,
                              end: picked,
                            );
                          } else {
                            _dateRange = DateTimeRange(start: picked, end: end);
                          }
                        });
                        _loadData();
                      }
                    },
                  ),
                  if (_dateRange?.start != null)
                    Text(
                      DateFormat('dd/MM').format(_dateRange!.start),
                      style: const TextStyle(fontSize: 12),
                    ),
                  const Text(' - '),
                  IconButton(
                    icon: const Icon(Icons.event_available_outlined, size: 20),
                    tooltip: 'Hasta',
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateRange?.end ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          final start = _dateRange?.start ?? DateTime.now();
                          // Ensure end is after start
                          if (picked.isBefore(start)) {
                            _dateRange = DateTimeRange(
                              start: picked,
                              end: picked,
                            );
                          } else {
                            _dateRange = DateTimeRange(
                              start: start,
                              end: picked,
                            );
                          }
                        });
                        _loadData();
                      }
                    },
                  ),
                  if (_dateRange?.end != null)
                    Text(
                      DateFormat('dd/MM').format(_dateRange!.end),
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  tooltip: 'Limpiar Filtro',
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
                      itemCount: invoices.length,
                      physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  String _dateFormatRange(DateTimeRange? range) {
    if (range == null) return 'Todo el Historial';
    final start = DateFormat('dd/MM/yy').format(range.start);
    final end = DateFormat('dd/MM/yy').format(range.end);
    return '$start - $end';
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
