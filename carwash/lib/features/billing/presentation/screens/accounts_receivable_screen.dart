import 'package:carwash/core/utils/export_service.dart';
import 'package:carwash/features/entry/domain/entities/client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/invoice.dart';
import '../providers/billing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'client_account_detail_screen.dart';

class AccountsReceivableScreen extends StatefulWidget {
  const AccountsReceivableScreen({super.key});

  @override
  State<AccountsReceivableScreen> createState() =>
      _AccountsReceivableScreenState();
}

class _AccountsReceivableScreenState extends State<AccountsReceivableScreen> {
  bool _isLoading = true;
  List<Invoice> _invoices = [];
  String _filter = 'todo'; // todo, vencido

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        final billingProvider = context.read<BillingProvider>();
        final invoices = await billingProvider.getReceivables(user.companyId);
        if (mounted) {
          setState(() {
            _invoices = invoices;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Invoice> get _filteredInvoices {
    if (_filter == 'vencido') {
      final now = DateTime.now();
      return _invoices
          .where((i) => i.dueDate != null && i.dueDate!.isBefore(now))
          .toList();
    }
    return _invoices; // 'todo' includes pendiente, parcial, vencido
  }

  // Helper to group invoices by client
  List<Map<String, dynamic>> get _groupedClients {
    final Map<String, List<Invoice>> groups = {};

    for (var invoice in _filteredInvoices) {
      if (!groups.containsKey(invoice.clientId)) {
        groups[invoice.clientId] = [];
      }
      groups[invoice.clientId]!.add(invoice);
    }

    // Convert to List of Client Summary objects/maps
    return groups.entries.map((entry) {
      final invoices = entry.value;
      final first = invoices.first;
      final totalDebt = invoices.fold(
        0.0,
        (sum, i) => sum + (i.totalAmount - i.paidAmount),
      );

      return {
        'clientId': entry.key,
        'clientName': first.clientName,
        'clientRtn': first.clientRtn,
        'companyId': first.companyId,
        'totalDebt': totalDebt,
        'invoiceCount': invoices.length,
        'oldestDueDate': invoices
            .map((i) => i.dueDate)
            .whereType<DateTime>()
            .reduce((a, b) => a.isBefore(b) ? a : b),
        // Use the first invoice reference to build the client object later
        'referenceInvoice': first,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupedList = _groupedClients;
    // Calculate total pending from the grouped list (should be same as raw sum)
    final totalPending = groupedList.fold(
      0.0,
      (sum, item) => sum + (item['totalDebt'] as double),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cuentas por Cobrar',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar Reporte',
            onPressed: () async {
              if (_groupedClients.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay datos para exportar')),
                );
                return;
              }
              await ExportService().exportAccountsReceivableToPdf(
                _groupedClients,
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'todo',
                child: Text('Todas las pendientes'),
              ),
              const PopupMenuItem(
                value: 'vencido',
                child: Text('Solo Vencidas'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL PENDIENTE',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  'L. ${totalPending.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupedList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 60,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No hay cuentas pendientes',
                          style: GoogleFonts.outfit(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: groupedList.length,
                    itemBuilder: (context, index) {
                      final item = groupedList[index];
                      final isOverdue =
                          (item['oldestDueDate'] as DateTime?)?.isBefore(
                            DateTime.now(),
                          ) ??
                          false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              (item['clientName'] as String)[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item['clientName'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['invoiceCount']} facturas pendientes',
                              ),
                              if (isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(top: 4),
                                  color: Colors.red.shade100,
                                  child: const Text(
                                    'FACTURAS VENCIDAS',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'L. ${(item['totalDebt'] as double).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientAccountDetailScreen(
                                  client: Client(
                                    id: item['clientId'],
                                    fullName: item['clientName'],
                                    phone: '',
                                    companyId: item['companyId'],
                                    rtn: item['clientRtn'],
                                    address: '',
                                    email: '',
                                    // creditProfile default
                                    active: true,
                                  ),
                                ),
                              ),
                            ).then((_) => _loadInvoices());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
