import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../branch/domain/entities/branch.dart';
// import 'package:provider/provider.dart';

class BalanceFilterSheet extends StatefulWidget {
  final DateTime? currentDateStart;
  final DateTime? currentDateEnd;
  final String? currentBranchId;
  final String? currentDocumentType;
  final List<Branch> branches;
  final Function(
    DateTime? start,
    DateTime? end,
    String? branchId,
    String? documentType,
  )
  onApply;

  const BalanceFilterSheet({
    super.key,
    required this.currentDateStart,
    required this.currentDateEnd,
    required this.currentBranchId,
    required this.currentDocumentType,
    required this.branches,
    required this.onApply,
  });

  @override
  State<BalanceFilterSheet> createState() => _BalanceFilterSheetState();
}

class _BalanceFilterSheetState extends State<BalanceFilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _branchId;
  late String? _documentType;

  @override
  void initState() {
    super.initState();
    _startDate = widget.currentDateStart;
    _endDate = widget.currentDateEnd;
    _branchId = widget.currentBranchId;
    _documentType = widget.currentDocumentType;
  }

  void _reset() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _branchId = null;
      _documentType = null;
    });
  }

  void _apply() {
    widget.onApply(_startDate, _endDate, _branchId, _documentType);
    Navigator.pop(context);
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list_alt, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 12),
                  Text(
                    'Filtros de Balance',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _reset,
                child: Text(
                  'Restablecer',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E88E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // BRANCH (Combobox style but custom container to match theme)
          if (widget.branches.isNotEmpty) ...[
            _buildSectionTitle('SUCURSAL'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _branchId,
                  hint: Text(
                    'Todas las Sucursales',
                    style: GoogleFonts.outfit(color: Colors.black54),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Todas las Sucursales',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ...widget.branches.map(
                      (b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name, style: GoogleFonts.outfit()),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _branchId = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // DATE RANGE
          _buildSectionTitle('RANGO DE FECHAS'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'Desde',
                  _startDate,
                  () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  'Hasta',
                  _endDate,
                  () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // DOCUMENT TYPE (Combobox)
          _buildSectionTitle('TIPO DE DOCUMENTO'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _documentType,
                hint: Text(
                  'Todos los Documentos',
                  style: GoogleFonts.outfit(color: Colors.black54),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Todos los Documentos',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'invoice',
                    child: Text(
                      'Facturación (Fiscal)',
                      style: GoogleFonts.outfit(),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'receipt',
                    child: Text(
                      'Recibos (Balance)',
                      style: GoogleFonts.outfit(),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _documentType = val),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Apply Button
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Aplicar Filtros',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : 'Seleccionar',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
