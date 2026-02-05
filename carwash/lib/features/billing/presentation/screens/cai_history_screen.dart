import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/entities/fiscal_config.dart';
import '../providers/billing_provider.dart';
import 'cai_invoices_screen.dart';

class CaiHistoryScreen extends StatefulWidget {
  final String companyId;
  final String branchId;

  const CaiHistoryScreen({
    super.key,
    required this.companyId,
    required this.branchId,
  });

  @override
  State<CaiHistoryScreen> createState() => _CaiHistoryScreenState();
}

class _CaiHistoryScreenState extends State<CaiHistoryScreen> {
  bool _isLoading = true;
  List<FiscalConfig> _history = [];
  FiscalConfig? _activeConfig;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<BalanceRepository>();

      // Load History
      final history = await repo.getFiscalHistory(
        widget.companyId,
        widget.branchId,
      );

      // Get Active from Provider (should be loaded for this branch context typically)
      // Or fetch fresh? Let's use provider's if available or fetch.
      // Since we are coming from Config Screen, Provider should have it.
      if (!mounted) return;
      final providerConfig = context.read<BillingProvider>().fiscalConfig;

      if (mounted) {
        setState(() {
          _history = history;
          _activeConfig = providerConfig;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      log('Error loading history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Historial de CAI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_activeConfig != null) ...[
                  Text(
                    'CAI ACTIVO',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ActiveCaiCard(config: _activeConfig!),
                  const SizedBox(height: 24),
                ],

                Text(
                  'HISTORIAL ANTERIOR',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay historial registrado.'),
                  )
                else
                  ..._history.map((c) => _HistoryCaiCard(config: c)),
              ],
            ),
    );
  }
}

class _ActiveCaiCard extends StatelessWidget {
  final FiscalConfig config;
  const _ActiveCaiCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final deadline = config.deadline ?? now;
    final daysLeft = deadline.difference(now).inDays;

    final totalRange = (config.rangeMax ?? 0) - (config.rangeMin ?? 0);
    final used = config.currentSequence - (config.rangeMin ?? 0);
    final percent = totalRange > 0 ? (used / totalRange).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaiInvoicesScreen(
                companyId: config.companyId,
                fiscalConfig: config,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      config.cai ?? 'Sin CAI',
                      style: GoogleFonts.robotoMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vencimiento',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(deadline),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (daysLeft < 30)
                        Text(
                          '$daysLeft días restantes',
                          style: TextStyle(
                            color: daysLeft < 10 ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Secuencia',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${config.currentSequence} / ${config.rangeMax}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Uso del Rango',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation(
                  percent > 0.9
                      ? Colors.red
                      : (percent > 0.7 ? Colors.orange : Colors.blue),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCaiCard extends StatelessWidget {
  final FiscalConfig config;
  const _HistoryCaiCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaiInvoicesScreen(
                companyId: config.companyId,
                fiscalConfig: config,
              ),
            ),
          );
        },
        leading: const Icon(Icons.history, color: Colors.grey),
        title: Text(
          config.cai ?? 'N/A',
          style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey[800]),
        ),
        subtitle: Text(
          'Venció: ${config.deadline != null ? DateFormat('dd/MM/yyyy').format(config.deadline!) : 'N/A'}\nSecuencia Final: ${config.currentSequence}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
